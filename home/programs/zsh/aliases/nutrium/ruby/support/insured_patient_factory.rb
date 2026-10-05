require_relative "summary"

# Builds a login-ready patient that belongs to an insurance-based company, i.e.
# one the reimbursement funnel is open to. The funnel only unlocks for a patient
# whose `nutrium_care_company` has `insurance_based` on, so the company is the
# one thing this factory refuses to guess wrong: it either takes a code or picks
# an insured company that already exists, and tells you to seed one otherwise.
#
# The state is deliberately optional. Left off, the patient starts at the very
# first step the app asks for ("state"); passed, that step is already satisfied
# and the flow starts at the insurance profile.
module InsuredPatientFactory
  module_function

  PASSWORD = "1234567aAa!".freeze

  # Returns { patient:, created:, company:, state:, professional: }.
  def create(email:, name:, company_code:, state_code:, professional_name:)
    company      = resolve_company(company_code)
    state        = resolve_state(state_code)
    professional = resolve_professional(professional_name)

    existing = Account.find_by(email: email)
    return reuse(existing.patient, company, state, company_code, state_code) if existing&.patient

    patient = build(email: email, name: name, company: company, state: state, professional: professional)

    ActiveRecord::Base.transaction do
      patient.save!
      patient.account.update_columns(confirmed_at: Time.zone.now)
      # Webhooks off: a seeded patient should not be announced to whatever partner
      # integrations the environment happens to have configured. The meal plan and
      # the tags are both owned by a professional, so a patient seeded without one
      # skips them — the piece that matters here is the company association, which
      # is what `nutrium_care_company` reads.
      PatientFactory.create_relationships(
        self, patient.account, patient,
        skip_webhook:  true,
        skip_meal_plan: professional.nil?,
        skip_tags:      professional.nil?
      )
    end

    { patient: patient, created: true, company: company, state: state, professional: professional }
  end

  def build(email:, name:, company:, state:, professional:)
    Patient.new do |p|
      p.account                                 = Account.new(email: email, password: PASSWORD, account_setting: AccountSetting.new)
      p.name                                    = name
      p.birthdate                               = Date.new(1990, 6, 15)
      p.gender                                  = Gender::FEMALE
      p.country_of_residence                    = Country.find_by!(code: "US")
      p.administrative_division_of_residence    = state
      p.company                                 = company
      p.patient_origin_id                       = PatientOrigin::COMPANY
      p.master_patient_for_account              = true
      p.time_zone                               = company.time_zone
      # Defaults to true on the column, and the model then demands a professional.
      p.has_professional                        = professional.present?

      if professional
        p.professionals << professional
        p.workplace      = professional.workplaces.first
      end
    end
  end

  # Re-running the same email never duplicates the account. It does move the
  # patient on, though: passing --company or --state applies to the existing row,
  # which is how you walk a patient forward through the setup steps by hand.
  def reuse(patient, company, state, company_code, state_code)
    changes = {}
    changes[:company] = company if company_code.present?
    changes[:administrative_division_of_residence] = state if state_code.present?
    patient.update!(changes) if changes.any?

    {
      patient:      patient,
      created:      false,
      company:      patient.nutrium_care_company,
      state:        patient.administrative_division_of_residence,
      professional: patient.professionals.first
    }
  end

  def resolve_company(code)
    if code.present?
      company = Company.find_by(code: code) || raise(ArgumentError, "Company with code '#{code}' not found.")
      unless company.insurance_based?
        raise ArgumentError,
              "Company '#{code}' is not insurance_based, so the reimbursement funnel stays closed for " \
              "its patients. Run `nut seed insured-company --code #{code}` first."
      end
      return company
    end

    Company.where(insurance_based: true).order(:id).first ||
      raise(ArgumentError,
            "No insurance-based company exists. Run `nut seed insured-company` first, or pass " \
            "--company <code>.")
  end

  def resolve_state(code)
    return nil if code.blank?

    us = Country.find_by!(code: "US")
    AdministrativeDivision.find_by(country: us, code: code.to_s.upcase) ||
      raise(ArgumentError, "'#{code}' is not a US state code (expected e.g. CA, NY, TX).")
  end

  def resolve_professional(name)
    return nil if name.blank?

    Professional.find_by(name: name) ||
      raise(ArgumentError, "Professional '#{name}' not found. Seed one first (e.g. nut seed professional).")
  end

  # The setup steps the patient still owes, judged from local rows only. The API
  # answers the consents step from the versions Bridge publishes, so this line is
  # a local approximation of that one — it can't see a version Bridge has since
  # republished.
  def missing_data(patient)
    profile = patient.account.insurance_profile
    missing = []

    missing << "state"             if patient.administrative_division_of_residence_id.blank?
    missing << "insurance_profile" if profile&.bridge_patient_id.blank?
    missing << "policy"            unless profile&.insurance_policies&.any? { |policy| policy.current? && policy.status.confirmed? }
    missing << "consents"          if profile.nil? || profile.insurance_consents.none?

    missing
  end
end

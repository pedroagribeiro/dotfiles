require_relative "summary"

# Moves an existing patient's own fields so a seeded patient can be walked through the reimbursement
# setup by hand, one step at a time, without going back to the console.
#
# Only the fields actually passed are touched — everything else is left exactly as it was — so the
# same command can be re-run to nudge one value without disturbing the rest. The fields on offer are
# the ones the insurance flow reads: the residence state gates the eligibility check, and the
# birthdate, street address and ZIP are what the profile sends on to Bridge as the patient's identity
# and address.
module PatientUpdater
  module_function

  # The word that clears a field rather than setting it, so a step can be replayed from the start.
  CLEAR = "none".freeze

  # Returns { patient:, changed:, before: }.
  def update(email:, state_code:, zip_code:, address:, birthdate:, company_code:, name:)
    patient = find_patient!(email)
    before  = snapshot(patient)
    changes = {}

    changes[:administrative_division_of_residence] = resolve_state(state_code) if state_code.present?
    changes[:company]                              = resolve_company(company_code) if company_code.present?
    changes[:zip_code]                             = clearable(zip_code) if zip_code.present?
    changes[:address]                              = clearable(address) if address.present?
    changes[:birthdate]                            = parse_date(birthdate) if birthdate.present?
    changes[:name]                                 = name if name.present?

    patient.update!(changes) if changes.any?

    { patient: patient, changed: changes.keys, before: before }
  end

  def find_patient!(email)
    account = Account.find_by(email: email)
    raise ArgumentError, "No account with email '#{email}'." if account.nil?

    account.patient || raise(ArgumentError, "Account '#{email}' exists but has no patient.")
  end

  def snapshot(patient)
    {
      state:     patient.administrative_division_of_residence&.code,
      company:   patient.nutrium_care_company&.code,
      zip_code:  patient.zip_code,
      address:   patient.address,
      birthdate: patient.birthdate,
      name:      patient.name
    }
  end

  def clearable(value)
    value.to_s.casecmp?(CLEAR) ? nil : value
  end

  def resolve_state(code)
    return nil if code.to_s.casecmp?(CLEAR)

    us = Country.find_by!(code: "US")
    AdministrativeDivision.find_by(country: us, code: code.to_s.upcase) ||
      raise(ArgumentError, "'#{code}' is not a US state code (expected e.g. CA, NY, TX, or '#{CLEAR}' to clear it).")
  end

  def resolve_company(code)
    company = Company.find_by(code: code) || raise(ArgumentError, "Company with code '#{code}' not found.")
    unless company.insurance_based?
      raise ArgumentError,
            "Company '#{code}' is not insurance_based, so the reimbursement funnel stays closed for its " \
            "patients. Run `nut seed insured-company --code #{code}` first."
    end
    company
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue Date::Error
    raise ArgumentError, "'#{value}' is not a date I can read (expected YYYY-MM-DD)."
  end

  # The setup steps the patient still owes, judged from local rows only. The API answers the consents
  # step from the versions Bridge publishes, so that one is an approximation here.
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

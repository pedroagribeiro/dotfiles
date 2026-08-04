require_relative "summary"

# Builds a login-ready secretary bound to an existing professional, optionally
# scoped to a single workplace, plus a few pending appointment requests so the
# secretary calendar has something to render. A secretary owns almost no data of
# its own — its patients, appointments and requests all belong to the
# professional — so we attach to a goodie-rich seed professional and only seed
# the requests that are otherwise missing.
module SecretaryFactory
  module_function

  PASSWORD = "1234567Aa!".freeze

  # Returns { secretary:, created:, professional:, requests_created:, auto_selected: }.
  # When no professional name is given we auto-pick one that can actually host
  # requests, since the "default" professional varies per environment (a sandbox
  # copy may have a bare one with no services/patients).
  def create(email:, name:, professional_name:, workplace_scoped:, requests:)
    # Reusing an existing secretary: never duplicate it. Report its real
    # professional (not an auto-pick), and top up requests only if it currently
    # sees none — e.g. it was first created against a professional that couldn't
    # host any. This makes re-running the same email safe and informative.
    existing = Account.find_by(email: email)
    if existing&.secretary
      secretary        = existing.secretary
      requests_created = 0
      if secretary.available_nutrition_service_requests.action_needed.none?
        ActiveRecord::Base.transaction do
          requests_created = seed_pending_requests(secretary.professional, secretary.workplace, requests)
        end
      end
      return { secretary: secretary, created: false, professional: secretary.professional, requests_created: requests_created, auto_selected: false }
    end

    auto_selected = professional_name.to_s.strip.empty?

    professional =
      if auto_selected
        best_professional_for_requests
      else
        Professional.find_by(name: professional_name)
      end

    if professional.nil?
      raise ArgumentError,
            "Professional '#{professional_name}' not found. Pass --professional <name>, " \
            "or seed one first (e.g. nut seed professional)."
    end

    unless professional.professional_setting&.scheduling_system_active?
      puts "Warning: '#{professional.name}' has the scheduling system disabled. Requests still " \
           "render, but the calendar legend (the bit this feature toggles) stays hidden. Pick a " \
           "professional with scheduling active to exercise the feature fully."
    end

    workplace = workplace_scoped ? professional.workplace : nil

    secretary =
      Secretary.new do |s|
        s.account              = Account.new(email: email, password: PASSWORD)
        s.professional         = professional
        s.name                 = name
        s.time_zone            = professional.time_zone
        s.language_id          = professional.language
        s.workplace            = workplace
        s.current_workplace_id = professional.workplace&.id
        s.secretary_origin_id  = SecretaryOrigin::PROFESSIONAL
      end

    requests_created = 0
    ActiveRecord::Base.transaction do
      secretary.save!
      secretary.account.skip_email_confirmation!
      requests_created = seed_pending_requests(professional, workplace, requests)
    end

    { secretary: secretary, created: true, professional: professional, requests_created: requests_created, auto_selected: auto_selected }
  end

  # Picks a professional that can actually host appointment requests: scheduling
  # active, has at least one nutrition service and one patient, preferring the
  # one with the most workplaces (so --workplace-scoped can exercise the
  # exclusion case). Scans professionals that have services and filters the rest
  # in Ruby, since scheduling status lives on professional_setting.
  def best_professional_for_requests
    candidate =
      Professional
        .joins(:nutrition_services)
        .distinct
        .includes(:professional_setting, :workplaces)
        .limit(300)
        .select { |professional| professional.professional_setting&.scheduling_system_active? && professional.patients.any? }
        .max_by { |professional| professional.workplaces.size }

    candidate || raise(ArgumentError,
      "No professional with scheduling active + a nutrition service + a patient was found to host " \
      "requests. Pass --professional <name> explicitly.")
  end

  # Seeds `count` pending, future requests on the professional. When the
  # secretary is workplace-scoped we drop the last one on a *different*
  # workplace, which must NOT appear for that secretary — an easy way to eyeball
  # the workplace-scoping filter.
  def seed_pending_requests(professional, scoped_workplace, count)
    count = count.to_i
    return 0 if count <= 0

    nutrition_service = professional.nutrition_services.first
    patient           = professional.patients.first
    if nutrition_service.nil? || patient.nil?
      puts "Skipping request seeding: professional '#{professional.name}' has no " \
           "nutrition_service/patient to attach a request to."
      return 0
    end

    primary_workplace = scoped_workplace || professional.workplace || professional.workplaces.first
    other_workplace   = professional.workplaces.where.not(id: primary_workplace&.id).first

    created = 0
    count.times do |i|
      workplace =
        if scoped_workplace && other_workplace && i == count - 1
          other_workplace
        else
          primary_workplace
        end

      NutritionServiceRequest.create!(
        nutrition_service:                   nutrition_service,
        patient:                             patient,
        workplace:                           workplace,
        date:                                (i + 1).days.from_now.change(hour: 10, min: 0),
        time_zone:                           professional.time_zone,
        uuid:                                SecureRandom.uuid,
        nutrition_service_request_status_id: NutritionServiceRequestStatus::PENDING,
        nutrition_service_request_reason_id: NutritionServiceRequestReason::WEIGHT_MANAGEMENT
      )
      created += 1
    end
    created
  end
end

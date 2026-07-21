require_relative "summary"

# Builds a fully bootstrapped professional (account, customer, consent, seller,
# 2FA, default patient + appointment) from a per-country config. The two entry
# scripts differ only in these values, so they live here as data instead of
# duplicated procedures. Add a country by adding a CONFIGS entry.
module ProfessionalFactory
  module_function

  PASSWORD = "1234567Aa!".freeze

  # `administrative_division_code` is optional (only some countries model it).
  CONFIGS = {
    "US" => {
      country_code:                 :US,
      administrative_division_code: "NY",
      gender:                       -> { Gender::MALE },
      phone_number:                 "12025550123",
      time_zone:                    "America/New_York",
      language:                     -> { Language::ENGLISH },
      profession_id:                -> { Profession::DIETITIAN },
      workplace_name:               "New York Nutrition Center",
      city:                         "New York"
    },
    "PT" => {
      country_code:                 :PT,
      administrative_division_code: nil,
      gender:                       -> { Gender::FEMALE },
      phone_number:                 "351210000000",
      time_zone:                    "Europe/Lisbon",
      language:                     -> { Language::PORTUGUESE },
      profession_id:                -> { Profession::NUTRITIONIST },
      workplace_name:               "Clínica de Nutrição de Lisboa",
      city:                         "Lisboa"
    }
  }.freeze

  # Returns { professional:, created: } so callers can report created vs reused.
  def create(country_code, email, name)
    config = CONFIGS.fetch(country_code.to_s.upcase) do
      raise ArgumentError, "Unknown country '#{country_code}'. Known: #{CONFIGS.keys.join(', ')}"
    end

    existing = Account.find_by(email: email)
    return { professional: existing.professional, created: false } if existing

    country  = Country.find_by!(code: config[:country_code])
    division  =
      if config[:administrative_division_code]
        AdministrativeDivision.find_by!(country: country, code: config[:administrative_division_code])
      end

    professional =
      Professional.new do |p|
        p.account                              = Account.new(email: email, password: PASSWORD, country_of_access: country)
        p.account.customer                     = Customer.new(country_of_billing: country, pricing_plan_type_id: PricingPlanType::ADDITIVE)
        p.country_of_residence                 = country
        p.administrative_division_of_residence = division if division
        p.name                                 = name
        p.gender                               = config[:gender].call
        p.phone_number                         = config[:phone_number]
        p.time_zone                            = config[:time_zone]
        p.language                             = config[:language].call
        p.profession_id                        = config[:profession_id].call
        p.workplaces                           = [Workplace.new(name: config[:workplace_name], country: country, city: config[:city], has_address: false)]
        p.current_workplace                    = p.workplaces[0]
        p.has_redesign_enabled                 = true
        p.account.consent                      = build_consent
      end

    ActiveRecord::Base.transaction do
      professional.account.save!
      professional.save!

      professional.create_default_patient_and_appointment

      DiscountCode.create_sign_up_discount_code(professional.account.customer)
      TrialExtensionCode.create_personal_trial_extension_code(professional.account.customer)

      Seller.create!(professional: professional, role_id: SellerRole::ADMIN)

      professional.account.skip_email_confirmation!
      professional.account.set_two_factor_authentication_method(TwoFactorAuthenticationMethod::EMAIL, true)
    end

    { professional: professional, created: true }
  end

  def build_consent
    Consent.new do |consent|
      now = Time.zone.now
      ip  = "0.0.0.0"

      consent.terms_of_use_and_privacy_policy_consented            = true
      consent.terms_of_use_and_privacy_policy_consented_at         = now
      consent.terms_of_use_and_privacy_policy_consented_from_ip    = ip
      consent.terms_of_use_and_privacy_policy_consented_on_sign_up = true
      consent.privacy_policy_consented_from_operating_system_id    = Device::OperatingSystem::WEB

      consent.marketing_consent_status_id    = MarketingConsentStatus::CONSENTED
      consent.marketing_consented_at         = now
      consent.marketing_consented_from_ip    = ip
      consent.marketing_consented_on_sign_up = true
    end
  end
end

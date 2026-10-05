require_relative "summary"

# Builds (or converts) a company whose patients go through the insurance
# reimbursement funnel. Membership of that funnel is one column —
# `companies.insurance_based` — so the factory's real job is that flag plus the
# US defaults the rest of the flow assumes (country of residence, time zone).
module InsuredCompanyFactory
  module_function

  DEFAULT_NAME      = "Insurance Test Co".freeze
  DEFAULT_TIME_ZONE = "America/New_York".freeze

  # Returns { company:, created:, flipped:, domain: }.
  # `flipped` is true when an existing company was switched on by this run, so
  # the summary can distinguish "already insured" from "just converted".
  def create(name:, code:, domain:)
    name   = name.presence || DEFAULT_NAME
    code   = code.presence || slugify(name)
    domain = domain.presence || default_domain(code)

    existing = Company.find_by(code: code)
    return convert(existing, domain) if existing

    company = Company.new do |c|
      c.name                               = name
      c.code                               = code
      c.insurance_based                    = true
      c.is_active                          = true
      c.demo                               = false
      c.time_zone                          = DEFAULT_TIME_ZONE
      c.allowed_countries_of_residence     = ["US"]
      c.allowed_professional_countries     = ["US"]
      # Verification off so any seeded email joins without needing an eligibility
      # entry that matches it; the domain below is only there for sign-up tests.
      c.requires_domain_verification       = false
      c.requires_collaborator_verification = false
    end
    company.save!
    ensure_domain(company, domain)

    { company: company, created: true, flipped: true, domain: domain }
  end

  def convert(company, domain)
    if company.demo?
      raise ArgumentError,
            "Company '#{company.code}' is a demo company, and the model forbids insurance_based on " \
            "those. Pick another --code."
    end

    flipped = !company.insurance_based?
    company.update!(insurance_based: true) if flipped
    ensure_domain(company, domain)

    { company: company, created: false, flipped: flipped, domain: domain }
  end

  def ensure_domain(company, domain)
    return if domain.blank?

    CompanyEligibilityEntry.find_or_create_by!(
      company:       company,
      entry_type_id: EligibilityEntryType::EMAIL_DOMAIN,
      value:         domain.downcase
    )
  end

  def slugify(name)
    name.to_s.parameterize(separator: "_")
  end

  def default_domain(code)
    "#{code.to_s.tr('_', '-')}.com"
  end
end

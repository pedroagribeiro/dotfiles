require_relative "support/summary"

PASSWORD = '1234567aAa!'.freeze

# The patient is attached to an existing seed professional. The name is a
# parameter (not a buried magic string) so it can point at whatever the current
# backup contains; it defaults to the professional our backups ship with.
DEFAULT_PROFESSIONAL_NAME = 'Ana Silva Magalhães'.freeze

def create_personalized_patient_from_company(email, company_code, professional_name)
  account = Account.new(email: email, password: PASSWORD, account_setting: AccountSetting.new)

  company = Company.find_by!(code: company_code)

  professional = Professional.find_by(name: professional_name)
  if professional.nil?
    abort "Professional '#{professional_name}' not found. Pass a valid name as the " \
          "3rd argument, or seed one first (e.g. create_pt_professional)."
  end
  professional.update(country_of_residence: Country.find_by(code: :PT))

  patient = Patient.new do |patient|
    patient.account              = account
    patient.professionals        << professional
    patient.has_professional     = true
    patient.workplace            = professional.workplaces.first
    patient.name                 = 'Pedro Ribeiro'
    patient.birthdate            = Date.new(1999, 3, 29)
    patient.gender               = Gender::MALE
    patient.phone_number         = '0351916669693'
    patient.country_of_residence = professional.country_of_residence || Country.find_by(code: :PT)
    patient.company              = company
    patient.patient_origin_id    = PatientOrigin::COMPANY
  end

  patient.save!
  patient.account.update_columns(confirmed_at: Time.zone.now)

  PatientFactory.create_relationships(self, patient.professional.account, patient)

  patient
end

email             = ARGV[0]
company_code      = ARGV[1]
professional_name = ARGV[2].presence || DEFAULT_PROFESSIONAL_NAME

# Idempotent: re-running with the same email reuses the patient instead of
# creating a duplicate account.
existing = Account.find_by(email: email)
created  = existing.nil?

patient =
  if existing
    puts "Account #{email} already exists (patient ##{existing.patient&.id}) — reusing."
    puts "Login: #{email} / #{PASSWORD}"
    existing.patient
  else
    create_personalized_patient_from_company(email, company_code, professional_name)
  end

SeedSummary.print("Patient", {
  "ID"           => patient.id,
  "Name"         => patient.name,
  "Login"        => "#{email} / #{PASSWORD}",
  "Status"       => created ? "created" : "reused",
  "Birthdate"    => patient.birthdate,
  "Gender"       => patient.gender == Gender::MALE ? "male" : "female",
  "Country"      => patient.country_of_residence&.code,
  "Professional" => patient.professionals.first&.name,
  "Workplace"    => patient.workplace&.name,
  "Company"      => patient.company&.name
})

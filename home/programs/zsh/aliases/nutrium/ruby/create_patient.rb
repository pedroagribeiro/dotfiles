def create_personalized_patient_from_company(email, company_code)
  account = Account.new(email: email, password: '1234567aAa!', account_setting: AccountSetting.new)

  company = Company.find_by!(code: company_code)

  professional = Professional.find_by!(name: 'Ana Silva Magalhães')
  professional.update(country_of_residence: Country.find_by(code: :PT))

  patient = Patient.new do |patient|
    patient.account              = account
    patient.professionals        << professional if professional
    patient.has_professional     = professional != nil
    patient.workplace            = professional.workplaces.first if professional
    patient.name                 = 'Pedro Ribeiro'
    patient.birthdate            = Date.new(1999, 3, 29)
    patient.gender               = Gender::MALE
    patient.phone_number         = '0351916669693'
    patient.country_of_residence = professional&.country_of_residence || Country.find_by(code: :PT)
    patient.company              = company
    patient.patient_origin_id    = PatientOrigin::COMPANY
  end

  patient.save!
  patient.account.update_columns(confirmed_at: Time.zone.now)

  PatientFactory.create_relationships(self, patient.professional.account, patient) if professional
end

email        = ARGV[0]
company_code = ARGV[1]

create_personalized_patient_from_company(email, company_code)

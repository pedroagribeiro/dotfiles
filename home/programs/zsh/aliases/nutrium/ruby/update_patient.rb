require_relative "support/patient_updater"

email        = ARGV[0]
state_code   = ARGV[1].to_s
zip_code     = ARGV[2].to_s
address      = ARGV[3].to_s
birthdate    = ARGV[4].to_s
company_code = ARGV[5].to_s
name         = ARGV[6].to_s

result  = PatientUpdater.update(
  email:        email,
  state_code:   state_code,
  zip_code:     zip_code,
  address:      address,
  birthdate:    birthdate,
  company_code: company_code,
  name:         name
)
patient = result[:patient]
profile = patient.account.insurance_profile
before  = result[:before]

if result[:changed].empty?
  puts "Nothing to change — pass at least one field (e.g. --state CA). Showing the patient as it stands."
else
  result[:changed].each do |field|
    was = before[field == :administrative_division_of_residence ? :state : field]
    puts "#{field}: #{was.presence || '—'} -> #{PatientUpdater.snapshot(patient)[field == :administrative_division_of_residence ? :state : field].presence || '—'}"
  end
end

SeedSummary.print("Patient", {
  "ID"             => patient.id,
  "Name"           => patient.name,
  "Email"          => patient.account.email,
  "Company"        => patient.nutrium_care_company ? "#{patient.nutrium_care_company.name} (#{patient.nutrium_care_company.code})" : nil,
  "Reimbursement"  => patient.nutrium_care_company&.insurance_based? ? "enabled" : "disabled",
  "State"          => patient.administrative_division_of_residence ? "#{patient.administrative_division_of_residence.code} — #{patient.administrative_division_of_residence.name}" : nil,
  "Address"        => patient.address,
  "ZIP"            => patient.zip_code,
  "Birthdate"      => patient.birthdate,
  "Bridge patient" => profile&.bridge_patient_id,
  "Policies"       => profile ? profile.insurance_policies.count : 0,
  "Consents"       => profile ? profile.insurance_consents.count : 0,
  "Missing data"   => PatientUpdater.missing_data(patient)
})

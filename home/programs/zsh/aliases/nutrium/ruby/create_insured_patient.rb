require_relative "support/insured_patient_factory"

email             = ARGV[0]
name              = ARGV[1].presence || "Insurance Tester"
company_code      = ARGV[2].to_s
state_code        = ARGV[3].to_s
professional_name = ARGV[4].to_s

result  = InsuredPatientFactory.create(
  email:             email,
  name:              name,
  company_code:      company_code,
  state_code:        state_code,
  professional_name: professional_name
)
patient = result[:patient]
profile = patient.account.insurance_profile

unless result[:created]
  puts "Account #{email} already exists (patient ##{patient.id}) — reusing."
  puts "Login: #{email} / #{InsuredPatientFactory::PASSWORD}"
end

SeedSummary.print("Insured patient", {
  "ID"             => patient.id,
  "Name"           => patient.name,
  "Login"          => "#{email} / #{InsuredPatientFactory::PASSWORD}",
  "Status"         => result[:created] ? "created" : "reused",
  "Company"        => "#{result[:company]&.name} (#{result[:company]&.code})",
  "Reimbursement"  => result[:company]&.insurance_based? ? "enabled" : "disabled",
  "State"          => result[:state] ? "#{result[:state].code} — #{result[:state].name}" : nil,
  "Professional"   => result[:professional]&.name,
  "Bridge patient" => profile&.bridge_patient_id,
  "Policies"       => profile ? profile.insurance_policies.count : 0,
  "Consents"       => profile ? profile.insurance_consents.count : 0,
  "Missing data"   => InsuredPatientFactory.missing_data(patient)
})

puts
puts "Missing data is judged from local rows; the API asks Bridge for the consent versions in force."
puts "Next: GET /api/v2/patients/#{patient.id} as this account and read reimbursement.missing_data."

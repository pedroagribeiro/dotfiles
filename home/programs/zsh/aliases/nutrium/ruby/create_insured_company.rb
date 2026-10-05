require_relative "support/insured_company_factory"

name   = ARGV[0].to_s
code   = ARGV[1].to_s
domain = ARGV[2].to_s

result  = InsuredCompanyFactory.create(name: name, code: code, domain: domain)
company = result[:company]

status =
  if result[:created]  then "created"
  elsif result[:flipped] then "converted"
  else "reused"
  end

puts "Company '#{company.code}' already existed and was switched to insurance_based." if result[:flipped] && !result[:created]

SeedSummary.print("Insured company", {
  "ID"              => company.id,
  "Name"            => company.name,
  "Code"            => company.code,
  "Status"          => status,
  "Insurance based" => company.insurance_based?,
  "Active"          => company.is_active?,
  "Time zone"       => company.time_zone,
  "Residence"       => company.allowed_countries_of_residence,
  "Email domain"    => result[:domain],
  "Patients"        => company.patients.count
})

require_relative "support/professional_factory"

country_code = ARGV[0]
email        = ARGV[1]
name         = ARGV[2]

result       = ProfessionalFactory.create(country_code, email, name)
professional = result[:professional]

unless result[:created]
  puts "Account #{email} already exists (professional ##{professional&.id}) — reusing."
  puts "Login: #{email} / #{ProfessionalFactory::PASSWORD}"
end

country = professional.country_of_residence

SeedSummary.print("Professional", {
  "ID"           => professional.id,
  "Name"         => professional.name,
  "Login"        => "#{email} / #{ProfessionalFactory::PASSWORD}",
  "Status"       => result[:created] ? "created" : "reused",
  "Location"     => "#{professional.current_workplace&.city}, #{country&.code} (#{professional.time_zone})",
  "Profession"   => professional.profession&.code,
  "Confirmed"    => professional.account.confirmed_at.present?,
  "2FA"          => professional.account.otp_required_for_login ? "email" : "off",
  "Redesign"     => professional.has_redesign_enabled,
  "Seller"       => professional.seller&.role&.code,
  "Patients"     => professional.patients.count,
  "Appointments" => professional.appointments.count
})

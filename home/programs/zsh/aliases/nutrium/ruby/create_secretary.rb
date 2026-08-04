require_relative "support/secretary_factory"

# Leave --professional off to auto-pick a professional that can host requests
# (scheduling active + a service + a patient). The old hardcoded default varied
# per environment, so a bare sandbox copy of it seeded zero requests.
email             = ARGV[0]
name              = ARGV[1]
professional_name = ARGV[2].to_s
workplace_scoped  = ARGV[3] == "true"
requests          = (ARGV[4].presence || "3").to_i

result    = SecretaryFactory.create(
  email:             email,
  name:              name,
  professional_name: professional_name,
  workplace_scoped:  workplace_scoped,
  requests:          requests
)
secretary = result[:secretary]

puts "Auto-selected professional '#{result[:professional]&.name}' (pass --professional <name> to override)." if result[:auto_selected]

unless result[:created]
  puts "Account #{email} already exists (secretary ##{secretary&.id}) — reusing."
  puts "Login: #{email} / #{SecretaryFactory::PASSWORD}"
end

SeedSummary.print("Secretary", {
  "ID"               => secretary.id,
  "Name"             => secretary.name,
  "Login"            => "#{email} / #{SecretaryFactory::PASSWORD}",
  "Status"           => result[:created] ? "created" : "reused",
  "Professional"     => result[:professional]&.name,
  "Scheduling"       => result[:professional]&.professional_setting&.scheduling_system_active? ? "active" : "disabled",
  "Workplace scope"  => secretary.workplace ? secretary.workplace.name : "all workplaces",
  "Time zone"        => secretary.time_zone,
  "2FA"              => secretary.account.otp_required_for_login ? "email" : "off",
  "Pending requests" => secretary.available_nutrition_service_requests.action_needed.count,
  "Seeded this run"  => result[:requests_created]
})

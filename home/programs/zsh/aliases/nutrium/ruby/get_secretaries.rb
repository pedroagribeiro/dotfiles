# Read-only. Lists secretaries whose professional can actually exercise the
# appointment-requests feature: the scheduling system is active AND the
# secretary would see at least one pending/future request. Reports each one's
# workplace scope and the professional's workplace count so you can pick a
# scoped vs unscoped secretary (and a >=2-workplace professional for the
# workplace-exclusion case).

scanned    = 0
candidates = []

Secretary.includes(:account, :workplace, professional: [:professional_setting, :workplaces]).find_each do |secretary|
  scanned    += 1
  professional = secretary.professional
  next unless professional&.professional_setting&.scheduling_system_active?

  visible_requests = secretary.available_nutrition_service_requests.action_needed.count
  next if visible_requests.zero?

  candidates << {
    secretary:        secretary.name,
    email:            secretary.account.email,
    professional:     professional.name,
    scope:            secretary.workplace ? secretary.workplace.name : "all workplaces",
    workplaces:       professional.workplaces.count,
    visible_requests: visible_requests
  }
end

scoped        = candidates.count { |c| c[:scope] != "all workplaces" }
multiworkplace = candidates.count { |c| c[:workplaces] >= 2 }

puts "Scanned #{scanned} secretaries — #{candidates.size} usable (scheduling active + visible pending requests)."
puts "  #{scoped} workplace-scoped, #{candidates.size - scoped} all-workplaces; #{multiworkplace} with a >=2-workplace professional."
puts

if candidates.empty?
  puts "No usable secretary found. Seed one with: nut seed <target> secretary --email <e> --name <n> [--workplace-scoped]"
else
  candidates.sort_by { |c| -c[:visible_requests] }.first(30).each do |c|
    puts format("  %-22s (%-20s) scope=%-22s wps=%-2d reqs=%-2d <%s>",
                c[:secretary], c[:professional], c[:scope], c[:workplaces], c[:visible_requests], c[:email])
  end
  puts "  … (showing first 30)" if candidates.size > 30
end

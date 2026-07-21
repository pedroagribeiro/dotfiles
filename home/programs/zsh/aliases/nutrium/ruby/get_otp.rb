require_relative "support/summary"

# Prints the current 2FA / OTP code for an account. `current_otp` (devise-two-
# factor) is the exact value the app emails/SMSes at login — see
# AccountMailer#otp and SmsDeliveryJob. It's time-based (TOTP), so it's only
# valid for the current ~30s window.
#
# This is a read-only util: it never writes. If an account has no otp_secret
# (2FA never initialized) there is no OTP to compute, so we say so instead of
# generating one — generating would be a validated write with side effects.
email   = ARGV[0]
account = Account.find_by(email: email)

if account.nil?
  abort "No account found with email #{email.inspect}. Pass an existing account's email, e.g. `nut get-otp us-pro@nutrium.com`."
end

if account.otp_secret.blank?
  abort "Account #{email} has no otp_secret set — 2FA was never initialized, so there is no OTP to show."
end

SeedSummary.print("2FA / OTP", {
  "Account" => "#{account.name} (#{email})",
  "OTP"     => account.current_otp
})

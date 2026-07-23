require_relative "support/summary"

# "Destroys" a professional the same way the app itself does: it anonymises
# rather than hard-deleting (the app never hard-deletes — ~90 non-cascading FKs
# make it unsafe). `account.delete_and_anonymize_attributes` frees the original
# email (rewrites it to an encrypted form + marks the account DELETED), so the
# same email can be re-seeded. `professional.anonymize_attributes_and_relationships`
# scrubs the rest. Both run in one transaction, so a failure leaves nothing
# half-done. Reuses the app's own methods, so it stays correct as the schema grows.
email   = ARGV[0]
account = Account.find_by(email: email)

if account.nil?
  abort "No account found with email #{email.inspect}. Pass an existing professional's email."
end

professional = account.professional
if professional.nil?
  abort "Account #{email} has no professional (is it a patient account?). Nothing changed."
end

pro_id = professional.id
name   = professional.name

ActiveRecord::Base.transaction do
  professional.anonymize_attributes_and_relationships
  account.delete_and_anonymize_attributes
end

SeedSummary.print("Professional destroyed", {
  "ID"     => pro_id,
  "Name"   => name,
  "Email"  => email,
  "Status" => "anonymized — email freed for re-seeding"
})

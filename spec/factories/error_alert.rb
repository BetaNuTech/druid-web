FactoryBot.define do
  factory :error_alert do
    sequence(:fingerprint) { |n| Digest::SHA1.hexdigest("error-#{n}") }
  end
end

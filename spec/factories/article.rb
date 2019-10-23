FactoryBot.define do
  factory :article do
    articletype { 'help' }
    category { 'Welcome'}
    published { true }
    audience { 'all' }
    slug { nil }
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraphs(number: 40).join }
    
    factory :help_article do
      articletype {'help'}
    end

  end
end

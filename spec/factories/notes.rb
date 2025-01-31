FactoryBot.define do
  factory :note do
    utility
    user
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.sentence(word_count: 4) }
    note_type {['review', 'critique'].sample }
  end
end

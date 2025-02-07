FactoryBot.define do
  factory :note do
    utility
    user
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.sentence }
    note_type { 'critique' }

    trait :review do
      note_type { 'review' }
    end

    transient do
      sentece_word_count { Faker::Number.number(digits: 1) }
    end

    after(:build) do |note, evaluator|
      note.content = Faker::Lorem.sentence(word_count: evaluator.sentece_word_count)
    end
  end
end

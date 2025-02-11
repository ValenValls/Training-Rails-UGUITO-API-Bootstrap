FactoryBot.define do
  factory :utility do
    initialize_with do
      klass = type.constantize
      klass.new(attributes)
    end

    # Adds a number to the name to avoid duplicates and fail because of the uniqueness
    sequence(:name) { |n| "#{Faker::Lorem.word}#{n}" }
    type { Utility.subclasses.map(&:to_s).sample }
    short_word_count_threshold { 50 }
    medium_word_count_threshold { 100 }
  end
end

FactoryBot.define do
  factory :note do
    title { "MyString" }
    content { "MyString" }
    note_type { "" }
    user { nil }
  end
end

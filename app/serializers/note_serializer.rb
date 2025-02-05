class NoteSerializer < ActiveModel::Serializer
  attributes :id, :title
  attribute :note_type, key: :type
  attributes :word_count, :created_at, :content, :content_length
  belongs_to :user
end

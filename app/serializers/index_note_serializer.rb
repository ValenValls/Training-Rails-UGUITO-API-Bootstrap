class IndexNoteSerializer < ActiveModel::Serializer
  attributes :id, :title
  attribute :note_type, key: :type
  attribute :content_length
  delegate :content_length, to: :object
end

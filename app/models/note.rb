# == Schema Information
#
# Table name: notes
#
#  id         :bigint(8)        not null, primary key
#  title      :string           not null
#  content    :string           not null
#  note_type  :enum             not null
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  utility_id :bigint(8)        not null
#
class Note < ApplicationRecord
  validates :user_id, :utility_id, :content, :note_type, :title,
            presence: true
  validate :validate_word_count

  belongs_to :user
  belongs_to :utility
  enum note_type: { review: 0, critique: 1 }

  def review_exceeds_word_limit?
    note_type == 'review' && content_length != 'short'
  end

  def content_length
    short_word_count_threshold = utility.short_word_count_threshold
    medium_word_count_threshold = utility.medium_word_count_threshold
    return 'short' if word_count <= short_word_count_threshold
    return 'medium' if word_count <= medium_word_count_threshold
    'long'
  end

  def word_count
    content.split.size
  end

  private

  def validate_word_count
    return unless utility && review_exceeds_word_limit?
    error_message = I18n.t(
      'active_record.errors.note.review_too_long',
      utility_name: utility.name,
      limit: utility.short_word_count_threshold
    )
    errors.add(:content, error_message)
  end
end

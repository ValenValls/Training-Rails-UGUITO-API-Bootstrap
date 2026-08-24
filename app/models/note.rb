# == Schema Information
#
# Table name: notes
#
#  id         :bigint(8)        not null, primary key
#  title      :string           not null
#  content    :string           not null
#  note_type  :integer          not null
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

  def content_length
    case word_count
    when 0..short_threshold
      'short'
    when (short_threshold + 1)..medium_threshold
      'medium'
    else
      'long'
    end
  end

  def word_count
    content.split.size
  end

  private

  def validate_word_count
    return unless errors.blank? && review_exceeds_word_limit?
    error_message = I18n.t(
      'active_record.errors.note.review_too_long',
      utility_name: utility.name,
      limit: short_threshold
    )
    errors.add(:content, error_message)
  end

  def review_exceeds_word_limit?
    note_type == 'review' && content_length != 'short'
  end

  def short_threshold
    utility.short_word_count_threshold
  end

  def medium_threshold
    utility.medium_word_count_threshold
  end
end

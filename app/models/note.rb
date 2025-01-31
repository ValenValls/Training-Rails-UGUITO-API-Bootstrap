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

  belongs_to :user
  belongs_to :utility
  enum note_type: { review: 0, critique: 1 }

  def word_count
    content.split.size
  end
end

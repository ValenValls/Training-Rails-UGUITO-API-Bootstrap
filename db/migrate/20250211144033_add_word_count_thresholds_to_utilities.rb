class AddWordCountThresholdsToUtilities < ActiveRecord::Migration[6.1]
  def change
    add_column :utilities, :short_word_count_threshold, :integer
    add_column :utilities, :medium_word_count_threshold, :integer
  end
end

class AddUtilityToNote < ActiveRecord::Migration[6.1]
  def change
    add_reference :notes, :utility, null: false, foreign_key: true
  end
end

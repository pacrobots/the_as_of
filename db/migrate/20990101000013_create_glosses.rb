# frozen_string_literal: true

class CreateGlosses < ActiveRecord::Migration[8.1]
  def change
    create_table :glosses do |t|
      t.string :target_type, null: false
      t.string :target_id, null: false
      t.text :text, null: false
      t.json :source_ids
      t.string :status, null: false
      t.datetime :as_of_data
      t.string :prompt_hash, null: false
      t.string :input_hash, null: false
      t.string :model, null: false
      t.timestamps
    end
    add_index :glosses, %i[target_type target_id prompt_hash], unique: true
  end
end

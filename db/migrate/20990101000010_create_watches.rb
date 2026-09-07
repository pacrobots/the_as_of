# frozen_string_literal: true

class CreateWatches < ActiveRecord::Migration[8.1]
  def change
    create_table :watches do |t|
      t.json :entities, null: false
      t.references :customer, null: false, foreign_key: true
      t.timestamps
    end
  end
end

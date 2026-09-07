# frozen_string_literal: true

class CreateRules < ActiveRecord::Migration[8.1]
  def change
    create_table :rules do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.string :status, null: false
      t.date :effective_date
      t.json :supersedes
      t.string :fragment
      t.json :exposures
      t.json :open_questions
      t.references :source, foreign_key: true
      t.timestamps
    end
    add_index :rules, :code, unique: true
  end
end

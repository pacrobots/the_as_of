# frozen_string_literal: true

class CreateBriefs < ActiveRecord::Migration[8.1]
  def change
    create_table :briefs do |t|
      t.string :event_type, null: false
      t.string :headline, null: false
      t.string :status, null: false, default: "ok"
      t.json :entities
      t.json :jurisdictions
      t.json :claims
      t.json :numbers
      t.json :exposures
      t.json :next_dates
      t.json :open_questions
      t.json :supersedes
      t.json :sources_json
      t.references :source, foreign_key: true
      t.references :customer, foreign_key: true
      t.timestamps
    end
  end
end

# frozen_string_literal: true

class CreateFilings < ActiveRecord::Migration[8.1]
  def change
    create_table :filings do |t|
      t.string :accession, null: false
      t.string :cik, null: false
      t.string :form, null: false
      t.datetime :filed_at, null: false
      t.string :company_name
      t.references :source, null: false, foreign_key: true
      t.timestamps
    end
    add_index :filings, :accession, unique: true
  end
end

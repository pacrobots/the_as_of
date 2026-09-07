# frozen_string_literal: true

class CreateCredits < ActiveRecord::Migration[8.1]
  def change
    create_table :credits do |t|
      t.integer :balance_cents, null: false, default: 0
      t.references :customer, null: false, foreign_key: true
      t.timestamps
    end
  end
end

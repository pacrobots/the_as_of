# frozen_string_literal: true

class CreateCreditKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_keys do |t|
      t.string :key_hash, null: false
      t.string :prefix, null: false
      t.references :customer, null: false, foreign_key: true
      t.timestamps
    end
    add_index :credit_keys, :key_hash, unique: true
  end
end

# frozen_string_literal: true

class CreateUsageEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_events do |t|
      t.string :route, null: false
      t.integer :status, null: false
      t.integer :price_cents, null: false
      t.references :customer, null: false, foreign_key: true
      t.timestamps
    end
  end
end

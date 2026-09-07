# frozen_string_literal: true

class CreateSkuEntitlements < ActiveRecord::Migration[8.1]
  def change
    create_table :sku_entitlements do |t|
      t.string :sku, null: false
      t.integer :brief_cap_month
      t.integer :included_cents, null: false, default: 0
      t.references :customer, null: false, foreign_key: true
      t.timestamps
    end
  end
end

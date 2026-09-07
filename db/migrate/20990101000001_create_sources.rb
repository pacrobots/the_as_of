# frozen_string_literal: true

class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :kind, null: false
      t.string :native_id, null: false
      t.string :url, null: false
      t.datetime :retrieved_at, null: false
      t.datetime :published_at
      t.string :content_hash, null: false
      t.integer :bytes, null: false
      t.string :license, null: false, default: "unknown"
      t.timestamps
    end
    add_index :sources, :content_hash, unique: true
  end
end

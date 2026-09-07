# frozen_string_literal: true

class CreateFetchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :fetch_logs do |t|
      t.string :source_kind, null: false
      t.string :native_id
      t.string :url, null: false
      t.integer :http_status
      t.integer :bytes
      t.string :content_hash
      t.string :outcome, null: false
      t.string :error_class
      t.string :error_message
      t.integer :duration_ms
      t.timestamps
    end
    add_index :fetch_logs, %i[source_kind created_at]
    add_index :fetch_logs, :outcome
  end
end

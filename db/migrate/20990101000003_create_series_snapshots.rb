# frozen_string_literal: true

class CreateSeriesSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :series_snapshots do |t|
      t.string :name, null: false
      t.string :value, null: false
      t.string :unit, null: false
      t.string :vintage, null: false
      t.datetime :observed_at, null: false
      t.references :source, null: false, foreign_key: true
      t.timestamps
    end
    add_index :series_snapshots, %i[name observed_at], unique: true
  end
end

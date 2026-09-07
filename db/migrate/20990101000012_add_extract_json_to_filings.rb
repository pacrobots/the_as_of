# frozen_string_literal: true

class AddExtractJsonToFilings < ActiveRecord::Migration[8.1]
  def change
    add_column :filings, :facts, :json
    add_column :filings, :claims, :json
    add_column :filings, :sections, :json
  end
end

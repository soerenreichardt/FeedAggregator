class AddTopicsColumnToEntries < ActiveRecord::Migration[5.0]
  def change
    add_column :entries, :topics, :string
  end
end

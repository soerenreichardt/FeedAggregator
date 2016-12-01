class AddMediaContentColumnToEntries < ActiveRecord::Migration[5.0]
  def change
    add_column :entries, :media_content_url, :string
  end
end

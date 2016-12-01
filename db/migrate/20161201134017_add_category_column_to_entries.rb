class AddCategoryColumnToEntries < ActiveRecord::Migration[5.0]
  def change
    add_column :entries, :categories, :string
  end
end

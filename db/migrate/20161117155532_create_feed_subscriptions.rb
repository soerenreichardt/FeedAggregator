class CreateFeedSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :feed_subscriptions do |t|
      t.integer :user_id
      t.integer :feed_id

      t.timestamps
    end
    add_index :feed_subscriptions, :user_id
    add_index :feed_subscriptions, :feed_id
    add_index :feed_subscriptions, [:user_id, :feed_id], unique: true
  end
end

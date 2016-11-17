class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :users, through: :feed_subscriptions
  has_many :feed_subscriptions, class_name: "FeedSubscription",
											foreign_key: "feed_id",
											dependent: :destroy

  validates :name, presence: true
  validates :url, :format => { :with => URI::regexp(%w(http https)), :message => "Valid URL required"}
end

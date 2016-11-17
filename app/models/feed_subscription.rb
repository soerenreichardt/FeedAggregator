class FeedSubscription < ApplicationRecord
	belongs_to :user, class_name: "User"
	belongs_to :feed, class_name: "Feed"

	validates :user_id, presence: true
	validates :feed_id, presence: true
end

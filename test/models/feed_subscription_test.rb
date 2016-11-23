require 'test_helper'

class FeedSubscriptionTest < ActiveSupport::TestCase
  
  def setup
  	@feed_subscription = FeedSubscription.new( user_id: users(:michael).id,
  												feed_id: feeds(:ny_times).id )
  end

  test "should be valid" do
  	assert @feed_subscription.valid?
  end

  test "should require a user_id" do
  	@feed_subscription.user_id = nil
  	assert_not @feed_subscription.valid?
  end

  test "should require a feed_id" do
  	@feed_subscription.feed_id = nil
  	assert_not @feed_subscription.valid?
  end

  test "user should have access to feeds" do
  	user = users(:michael)
  	assert_not_nil user.feeds
  end

  test "feeds should count subscribing users" do
  	user = users(:michael)
  	feed = feeds(:ny_times)
  	user.subscribe(feed)
  	assert_same(feed.users.count, 1)
  end

end

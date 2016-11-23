class FeedSubscriptionsController < ApplicationController

	def subscribe
		if logged_in?
			if params[:id] == nil
				feed = @feed
			else
				feed = Feed.find(params[:id])
			end
			subscription = FeedSubscription.new(user_id: current_user.id, feed_id: feed.id)
			if subscription.save
				flash[:success] = 'Subscribed to ' + feed.name
				redirect_to :back
			else
				flash[:danger] = 'Failed to subscribe to ' + feed.name
			end
		end
	end

	def unsubscribe
		if logged_in?
			FeedSubscription.where(user_id: current_user.id, feed_id: params[:id]).destroy_all
			flash[:success] = 'Successfully unsubscribed from ' + Feed.find(params[:id]).name
			redirect_to :back
		end
	end

end

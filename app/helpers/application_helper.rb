module ApplicationHelper

	# Returns the full title on a per-page basis
	def full_title(page_title = '')
		base_title = "FeedAggregator"
		if page_title.empty?
			base_title
		else
			page_title + " | " + base_title
		end
	end

	def valid_object
		if @user != nil
			return @user
		elsif @feed != nil
			return @feed
		end
	end
end

require 'will_paginate/array'

class UsersController < ApplicationController

	def show
		@user = User.find(params[:id])
		@feeds = @user.feeds.paginate(page: params[:page])
	end

	def new
		@user = User.new
	end

	def create
		@user = User.new(user_params)
		if  @user.save
			log_in @user
			flash[:success] = "Welcome to FeedAlligator"
			redirect_to @user
		else
			render 'new'
		end
	end

	def dashboard
		if logged_in?
			if params[:search].present?
				@search = Entry.search do
					fulltext params[:search]
					with(:feed_id, current_user.feeds.map(&:id))
					if params[:category].present?
						with(:topics, params[:category])
					end
					order_by :published, :desc
					paginate(page: params[:page], per_page: 15)
				end
				@entries_list = @search.results
			else
				@entries_list = Array.new
				if params[:category].present?
					current_user.feeds.each do |feed|
						@entries_list.concat(feed.entries.where("topics LIKE ?", "%#{params[:category]}%"))
					end
				else
					current_user.feeds.each do |feed|
						@entries_list.concat(feed.entries)
					end
				end

				# sort by publish date
				@entries_list.sort_by! do |entry|
					entry[:published]
				end
				@entries_list.reverse!
				@entries_list = @entries_list.paginate(page: params[:page], per_page: 15)
			end
		end
	end

	private
		def user_params
			params.require(:user).permit(:name, :email, :password, :password_confirmation)
		end
end

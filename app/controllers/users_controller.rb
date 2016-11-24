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
			flash[:success] = "Welcome to the Sample App!"
			redirect_to @user
		else
			render 'new'
		end
	end

	def dashboard
		if logged_in?
			@entries_list = Array.new
			current_user.feeds.each do |feed|
				@entries_list.concat(feed.entries)
			end

			# sort by publish date
			@entries_list.sort_by! do |entry|
				entry[:published]
			end
			@entries_list.reverse!
			@entries_list = @entries_list.paginate(page: params[:page], per_page: 15)
		end
	end

	private
		def user_params
			params.require(:user).permit(:name, :email, :password, :password_confirmation)
		end
end

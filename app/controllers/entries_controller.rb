class EntriesController < ApplicationController
  before_action :set_feed, only: :index

  def index
    @search = Entry.search do 
      fulltext params[:search]    
    end
    @entries = @search.results
    #@entries = @feed.entries.order('published desc')
  end

  def show
    @entry = Entry.find(params[:id])
  end

  private
  def set_feed
    @feed = Feed.find(params[:id])
  end
end

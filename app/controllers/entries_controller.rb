class EntriesController < ApplicationController
  before_action :set_feed, only: :index

  def index
    @search = @feed.entries.search do 
      fulltext params[:search] do
		highlight = true
	  end
    end

    @entries = @search.results.paginate(page: params[:page], per_page: 15)
    if params[:search].blank?
      @entries = @feed.entries.all.paginate(page: params[:page], per_page: 15)
    end
  end

  def show
    @entry = Entry.find(params[:id])
  end

  private
  def set_feed
    @feed = Feed.find(params[:id])
  end
end

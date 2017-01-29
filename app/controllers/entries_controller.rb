class EntriesController < ApplicationController
  before_action :set_feed, only: :index

  #TODO: suche klappt nicht für einzelne Feeds!
  def index
    if params[:search].present?
      @search = Entry.search do |e|
        e.fulltext params[:search]
        #e.with(:feed_id, @feed.id)
        e.paginate(page: params[:page], per_page: 15)
      end
      @entries = @search.results
    else
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

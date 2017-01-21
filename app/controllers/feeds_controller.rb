require 'whatlanguage'
require 'nokogiri'
require 'stopwords'

class FeedsController < ApplicationController
  before_action :set_feed, only: [:show, :edit, :update, :destroy]

  # GET /feeds
  # GET /feeds.json
  def index
    @feeds = Feed.all
  end

  # GET /feeds/1
  # GET /feeds/1.json
  def show
  end

  # GET /feeds/new
  def new
    @feed = Feed.new
  end

  # GET /feeds/1/edit
  def edit
  end

  # POST /feeds
  # POST /feeds.json
  def create
    @feed = Feed.new(feed_params)

    respond_to do |format|
      if @feed.save
        parse_entries
        format.html { 
          redirect_to @feed
          flash[:success] = 'Feed was successfully created.' 
        }
        format.json { render :show, status: :created, location: @feed }
      else
        format.html { render :new }
        format.json { render json: @feed.errors, status: :unprocessable_entity }
      end
    end
    
  end

  # PATCH/PUT /feeds/1
  # PATCH/PUT /feeds/1.json
  def update
      destroy_entries
      respond_to do |format|
      if @feed.update(feed_params)
        parse_entries
        format.html { 
          redirect_to @feed
          flash[:success] = 'Feed was successfully updated.' 
        }
        format.json { render :show, status: :ok, location: @feed }
      else
        format.html { render :edit }
        format.json { render json: @feed.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_entries
    set_feed
    destroy_entries
    parse_entries
    if @feed.save
      flash[:success] = 'Feed entries successfully updated.'
      redirect_to feeds_url
    end
  end

  # DELETE /feeds/1
  # DELETE /feeds/1.json
  def destroy
    @feed.destroy
    respond_to do |format|
      format.html { 
        redirect_to feeds_url
        flash[:success] = 'Feed was successfully destroyed.' 
      }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feed
      @feed = Feed.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def feed_params
      params.require(:feed).permit(:name, :url, :description)
    end
    # Parse the feed URL and add all entries
    def parse_entries

      init_whatlanguage
      init_stopword_files

      content = Feedjira::Feed.fetch_and_parse @feed.url
      content.entries.each do |entry|

        local_entry = @feed.entries.where(title: entry.title).first_or_initialize
        local_entry.update_attributes(author: entry.author, url: entry.url,
                                      published: entry.published)

        # search for content
        entry_content = nil
        if entry.content
          entry_content = entry.content
        elsif entry.summary
          entry_content = entry.summary
        elsif entry.description
          entry_content = entry.description
        end

        # generate nokogiri document
        doc = Nokogiri::XML.fragment(entry_content)
        
        # categories
        if entry.categories
          init_whatlanguage
          category_list = Array.new
          entry.categories.each do |category|
            category_list.push(category)
            #category_list.push(@wl.language(category))
          end
          local_entry.update_attributes(categories: category_list)
        end

        # media content
        if !entry.image.nil?
          local_entry.update_attributes(media_content_url: entry.image)
        elsif !doc.css('img').first.nil?
          local_entry.update_attributes(media_content_url: doc.css('img').first['src'])
          doc.search('.//img').remove
        end

        # remove links
        doc.css('a').each { |node| node.replace(node.children) }

        # save content
        local_entry.update_attributes(content: doc.to_html)

        lang = @wl.language_iso(doc.to_html)
        content_without_stopwords = nil
        title_without_stopwords = nil
        if lang == :en
          content_without_stopwords = @en_stopwords_filter.filter doc.to_html.downcase.split
          title_without_stopwords = @en_stopwords_filter.filter entry.title.downcase.split
        elsif lang == :de
          content_without_stopwords = @de_stopwords_filter.filter doc.to_html.downcase.split
          title_without_stopwords = @de_stopwords_filter.filter entry.title.downcase.split
        end

        # print characteristic words
        text = Highscore::Content.new content_without_stopwords.join(" ")
        text.configure do
          set :ignore_case, true
          #set :stemming, true
        end

        title = Highscore::Content.new title_without_stopwords.join(" ")
        title.configure do
          set :ignore_case, true
        end

        keyword_list = Array.new
        title.keywords.top(2).each do |keyword|
          keyword_list.push(keyword.text)
        end
        text.keywords.top(10).each do |keyword|
          keyword_list.push(keyword.text)
        end
        p '############### KEYWORDS ###############'
        p keyword_list

      end
    end

    def destroy_entries
      @feed.entries.destroy_all
    end

    def init_whatlanguage
      if @wl.nil?
        @wl = WhatLanguage.new(:all)
      end
    end

    def init_stopword_files
      if @en_stopwords_filter.nil?
        en_stopwords = Array.new
        file = File.new(Rails.public_path + 'linguistic_data/stopwords_en.txt')
        while(line = file.gets)
          en_stopwords.push(line.strip)
        end
        file.close
        @en_stopwords_filter = Stopwords::Snowball::Filter.new "en"
      end

      if @de_stopwords_filter.nil?
        de_stopwords = Array.new
        file = File.new(Rails.public_path + 'linguistic_data/stopwords_de.txt')
        while(line = file.gets)
          de_stopwords.push(line.strip)
        end
        file.close
        p de_stopwords
        @de_stopwords_filter = Stopwords::Snowball::Filter.new "de"
      end
    end
end

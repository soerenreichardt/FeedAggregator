require 'whatlanguage'
require 'nokogiri'
require 'stopwords'
require 'certified'
require 'classifier'
require 'madeleine'

class FeedsController < ApplicationController
  before_action :set_feed, only: [:show, :edit, :update, :destroy]
  before_action :init_whatlanguage, only: [:parse_entries]
  before_action :init_stopword_files, only: [:parse_entries]

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
        format.js {}
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
      respond_to do |format|
      if @feed.update(feed_params)
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
    if @feed.save
      parse_entries
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

  def self.extract_keywords(doc, title)
    lang = @wl.language_iso(doc)
    content_without_stopwords = nil
    title_without_stopwords = nil
    if lang == :en
      content_without_stopwords = @en_stopwords_filter.filter doc.downcase.split
      title_without_stopwords = @en_stopwords_filter.filter title.downcase.split
    elsif lang == :de
      content_without_stopwords = @de_stopwords_filter.filter doc.downcase.split
      title_without_stopwords = @de_stopwords_filter.filter title.downcase.split
    end

    keyword_list = Array.new
    if !title_without_stopwords.nil?
      title = Highscore::Content.new title_without_stopwords.join(" ")
      title.configure do
        set :ignore_case, true
      end
      title.keywords.top(2).each do |keyword|
        keyword_list.push(keyword.text)
      end
    end

    if !content_without_stopwords.nil?
      text = Highscore::Content.new content_without_stopwords.join(" ")
      text.configure do
        set :ignore_case, true
        #set :stemming, true
      end
      text.keywords.top(10).each do |keyword|
        keyword_list.push(keyword.text)
      end
    end

    return keyword_list
  end

  def self.init_whatlanguage
    if @wl.nil?
      @wl = WhatLanguage.new(:all)
    end
  end

  def self.init_stopword_files
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
      @de_stopwords_filter = Stopwords::Snowball::Filter.new "de"
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

    def parse_entries

      self.class.init_whatlanguage
      self.class.init_stopword_files

      content = Feedjira::Feed.fetch_and_parse @feed.url
      content.entries.each do |entry|

        # search for content
        entry_content = ""
        if entry.content
          entry_content = entry.content
        elsif entry.summary
          entry_content = entry.summary
        #elsif entry.description
        #  entry_content = entry.description
        end

        # generate nokogiri document
        doc = Nokogiri::XML.fragment(entry_content)
        
        # categories
        category_list = Array.new
        if entry.categories
          entry.categories.each do |category|
            category_list.push(category.strip)
          end
        end

        # media content
        media_content = nil
        if !entry.image.nil?
          media_content = entry.image
        elsif !doc.css('img').first.nil?
          media_content = doc.css('img').first['src']
          doc.search('.//img').remove
        end

        # remove links
        doc.css('a').each { |node| node.replace(node.children) }
        doc.css('div').each { |node| node.replace(node.children) }

        # write entry
        local_entry = @feed.entries.create(
          title: entry.title, 
          author: entry.author,
          url: entry.url,
          published: entry.published,
          content: doc.to_html,
          categories: category_list,
          media_content_url: media_content
        )

        # extract keywords
        keyword_list = self.class.extract_keywords(doc.to_html, entry.title)

        # add categories to keywords
        keyword_list += category_list unless category_list.nil? or keyword_list.nil?

        # classify
        reference_feed = false
        APP_CATEGORIES.each do |category, value|
          if value["url"].include?(@feed.url)
            reference_feed = true
            CLASSIFIER.train(category, keyword_list.join(" "))
          end
        end

        classes = CLASSIFIER.classifications keyword_list.join(" ")
        local_entry.update_attributes(topics: classes.sort_by{ |k,v| v }.reverse.to_h.keys[0..1].join("/"))
        p classes.sort_by{ |k, v| v }.reverse.to_h

        p '############### KEYWORDS ###############'
        p keyword_list

      end
    end

    def destroy_entries
      @feed.entries.destroy_all
    end
end

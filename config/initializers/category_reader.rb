require 'classifier'
require 'nokogiri'
require 'whatlanguage'

APP_CATEGORIES = YAML.load_file("#{Rails.root.to_s}/config/categories.yml")
CLASSIFIER = Classifier::Bayes.new

FeedsController.init_whatlanguage
FeedsController.init_stopword_files

p 'Migrating classifier with data....'

feeds = Feed.all
APP_CATEGORIES.each do |category, value|
	CLASSIFIER.add_category category
	feeds.each do |feed|
		if value["url"].include?(feed.url)
			feed.entries.each do |entry|
				doc = Nokogiri::XML.fragment(entry.content)
				doc.css('a').each { |node| node.replace(node.children) }
        		doc.css('div').each { |node| node.replace(node.children) }
				keyword_list = FeedsController.extract_keywords doc.to_html, entry.title
				keyword_list += entry.categories.split(',') unless entry.categories.nil? or keyword_list.nil?
				CLASSIFIER.train(category, keyword_list.join(" "))
			end
		end
	end
end
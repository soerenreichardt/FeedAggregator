unless ( File.basename($0) == 'rake')
	require 'classifier'
	require 'nokogiri'
	require 'whatlanguage'
	require 'feedjira'
	require 'rubygems'
	require 'fast_stemmer'

	APP_CATEGORIES = YAML.load_file("#{Rails.root.to_s}/config/categories.yml")
	CLASSIFIER = Classifier::Bayes.new

	FeedsController.init_whatlanguage
	FeedsController.init_stopword_files

	p 'Migrating classifier with data....'

	feeds = Feed.all
	APP_CATEGORIES.each do |category, value|
		CLASSIFIER.add_category category
		value["url"].each do |url|
			feed = Feedjira::Feed.fetch_and_parse url
			feed.entries.each do |entry|
				doc = Nokogiri::XML.fragment(entry.content)
				doc.css('a').each { |node| node.replace(node.children) }
	    		doc.css('div').each { |node| node.replace(node.children) }
				keyword_list = FeedsController.extract_keywords doc.to_html, entry.title
				keyword_list += entry.categories.split(',') unless entry.categories.nil? or keyword_list.nil?
				keyword_list.map! { |keyword| Stemmer::stem_word(keyword.to_s) }
				CLASSIFIER.train(category, keyword_list.join(" "))
			end
		end
	end
end
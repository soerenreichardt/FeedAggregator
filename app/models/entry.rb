class Entry < ApplicationRecord
  belongs_to :feed

  validates :content, presence: true

  searchable do 
  	text :content, :title
  	date :published
  	integer :feed_id
  end
  	
end

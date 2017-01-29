class Entry < ApplicationRecord
  belongs_to :feed

  validates :content, presence: true

  searchable do 
  	text :content, :title
  	integer :feed_id
  end
  	
end

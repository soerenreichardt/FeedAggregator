class Entry < ApplicationRecord
  belongs_to :feed

  validates :content, presence: true

  searchable do 
	text :title, :boost => 3.5
  	text :content
  end
  	
end

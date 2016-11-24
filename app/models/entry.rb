class Entry < ApplicationRecord
  belongs_to :feed

  validates :content, presence: true
end

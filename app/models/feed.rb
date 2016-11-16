class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy

  validates :name, presence: true
  validates :url, :format => { :with => URI::regexp(%w(http https)), :message => "Valid URL required"}
end

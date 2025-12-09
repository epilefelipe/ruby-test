# frozen_string_literal: true

class Room
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, type: String
  field :name, type: String
  field :description, type: String
  field :description_panic, type: String

  embeds_many :exits, class_name: 'RoomExit'
  has_many :items

  index({ slug: 1 }, { unique: true })

  validates :slug, :name, presence: true

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
end

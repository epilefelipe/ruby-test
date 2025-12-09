# frozen_string_literal: true

class Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, type: String
  field :name, type: String
  field :description, type: String
  field :hint, type: String
  field :pickable, type: Boolean, default: false
  field :examinable, type: Boolean, default: true
  field :contains_items, type: Array, default: []
  field :reveals_clue, type: String
  field :interaction_type, type: String # terminal, door, container

  belongs_to :room, optional: true

  index({ slug: 1 }, { unique: true })

  validates :slug, :name, presence: true

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
end

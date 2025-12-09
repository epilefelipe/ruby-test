# frozen_string_literal: true

class Clue
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, type: String
  field :text, type: String
  field :source, type: String
  field :hint_level, type: Integer, default: 1

  index({ slug: 1 }, { unique: true })

  validates :slug, :text, presence: true

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
end

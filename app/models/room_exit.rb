# frozen_string_literal: true

class RoomExit
  include Mongoid::Document

  field :direction, type: String
  field :target_room_slug, type: String
  field :door_id, type: String
  field :locked, type: Boolean, default: false
  field :required_item, type: String
  field :hint, type: String

  embedded_in :room

  validates :direction, :target_room_slug, presence: true
end

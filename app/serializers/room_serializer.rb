# frozen_string_literal: true

class RoomSerializer < Blueprinter::Base
  identifier :slug, name: :id

  fields :name

  field :description do |room, options|
    session = options[:session]
    if session&.panic? && room.description_panic.present?
      room.description_panic
    else
      room.description
    end
  end

  view :with_items do
    association :items, blueprint: ItemSerializer, view: :list
  end
end

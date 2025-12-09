# frozen_string_literal: true

module Commands
  class LookCommand < BaseCommand
    private

    def perform
      room = session.current_room
      visible_items = room.items.reject { |i| examined_and_picked?(i) }

      success_result(
        room: serialize_room(room),
        items: visible_items.map { |i| ItemSerializer.render_as_hash(i, view: :list) },
        exits: build_exits(room)
      )
    end

    def examined_and_picked?(item)
      session.examined_items.include?(item.slug) && item.pickable
    end

    def serialize_room(room)
      RoomSerializer.render_as_hash(room, session: session)
    end

    def build_exits(room)
      room.exits.map do |exit_info|
        locked = exit_info.locked && !session.door_unlocked?(exit_info.door_id)
        dest_room = Room.find_by_slug(exit_info.target_room_slug)

        {
          direction: exit_info.direction,
          destination: dest_room&.name || exit_info.target_room_slug,
          locked: locked,
          hint: locked ? exit_info.hint : nil
        }.compact
      end
    end
  end
end

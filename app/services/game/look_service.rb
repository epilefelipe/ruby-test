# frozen_string_literal: true

module Game
  class LookService < BaseService
    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over

      room = session.current_room
      items = room.items.where(:slug.nin => session.examined_items.select { |i| Item.find_by_slug(i)&.pickable })

      result = {
        room: RoomSerializer.render_as_hash(room, session: session),
        items: items.map { |i| ItemSerializer.render_as_hash(i, view: :list) },
        exits: build_exits(room)
      }

      result[:panic] = panic_info if session.panic?
      result
    end

    private

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

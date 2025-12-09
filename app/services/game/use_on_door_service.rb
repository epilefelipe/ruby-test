# frozen_string_literal: true

module Game
  class UseOnDoorService < BaseService
    attr_reader :item_slug, :direction

    def initialize(session, item:, direction:)
      super(session)
      @item_slug = item
      @direction = direction
    end

    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over
      return { error: 'No tienes ese objeto.' } unless session.has_item?(item_slug)

      exit_door = find_exit_by_direction
      return { error: 'No hay puerta en esa dirección.' } unless exit_door
      return { error: 'Esa puerta ya está abierta.' } unless exit_door.locked
      return { error: 'Esa puerta ya está desbloqueada.' } if session.door_unlocked?(exit_door.door_id)
      return { error: 'Esa llave no funciona aquí.' } unless exit_door.required_item == item_slug

      # Desbloquear puerta
      session.unlock_door(exit_door.door_id)
      session.remove_from_inventory(item_slug)

      result = {
        success: true,
        message: '¡La llave encaja perfectamente! La puerta se abre con un crujido.',
        door_status: 'unlocked',
        item_consumed: true,
        new_exit_available: {
          direction: exit_door.direction,
          room_id: exit_door.target_room_slug
        }
      }

      result[:panic] = panic_info if session.panic?
      result
    end

    private

    def find_exit_by_direction
      session.current_room.exits.find { |e| e.direction == direction }
    end
  end
end

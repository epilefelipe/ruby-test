# frozen_string_literal: true

module Commands
  class UseOnDoorCommand < BaseCommand
    def undoable?
      true
    end

    def undo
      return unless @unlocked_door && @used_item

      session.unlocked_doors.delete(@unlocked_door)
      session.add_to_inventory(@used_item)
    end

    private

    def perform
      @unlocked_door = nil
      @used_item = nil

      return error_result('No tienes ese objeto.') unless session.has_item?(params[:item])

      exit_door = find_exit_by_direction
      return error_result('No hay puerta en esa dirección.') unless exit_door
      return error_result('Esa puerta ya está abierta.') unless exit_door.locked
      return error_result('Esa puerta ya está desbloqueada.') if session.door_unlocked?(exit_door.door_id)
      return error_result('Esa llave no funciona aquí.') unless exit_door.required_item == params[:item]

      unlock_door(exit_door)
    end

    def find_exit_by_direction
      session.current_room.exits.find { |e| e.direction == params[:direction] }
    end

    def unlock_door(exit_door)
      @unlocked_door = exit_door.door_id
      @used_item = params[:item]

      session.unlock_door(exit_door.door_id)
      session.remove_from_inventory(params[:item])

      success_result(
        success: true,
        message: '¡La llave encaja perfectamente! La puerta se abre con un crujido.',
        door_status: 'unlocked',
        item_consumed: true,
        new_exit_available: {
          direction: exit_door.direction,
          room_id: exit_door.target_room_slug
        }
      )
    end
  end
end

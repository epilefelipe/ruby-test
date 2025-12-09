# frozen_string_literal: true

module Commands
  class MoveCommand < BaseCommand
    def undoable?
      true
    end

    def undo
      return unless @previous_room

      session.update!(current_room_slug: @previous_room)
    end

    private

    def perform
      @previous_room = session.current_room_slug
      exit_door = find_exit

      return error_result('No hay salida en esa dirección.') unless exit_door

      if exit_locked?(exit_door)
        return success_result(
          success: false,
          message: 'La puerta está cerrada.',
          hint: exit_door.hint
        )
      end

      move_to_room(exit_door)
    end

    def find_exit
      session.current_room.exits.find { |e| e.direction == params[:direction] }
    end

    def exit_locked?(exit_door)
      exit_door.locked && !session.door_unlocked?(exit_door.door_id)
    end

    def move_to_room(exit_door)
      target_room = Room.find_by_slug(exit_door.target_room_slug)

      return process_victory(target_room) if target_room.slug == GameConstants::Rooms::SALIDA

      session.update!(current_room_slug: target_room.slug)

      result = success_result(
        success: true,
        previous_room: @previous_room,
        current_room: RoomSerializer.render_as_hash(target_room, session: session)
      )

      add_direction_warning(result) if session.panic?
      result
    end

    def process_victory(room)
      session.reload

      if session.lost?
        return error_result(
          session.ending_message,
          game_over: true,
          ending: {
            type: 'bad_ending',
            title: '¡TIEMPO AGOTADO!',
            description: session.ending_message
          }
        )
      end

      time_remaining = session.panic_time_remaining
      session.win!(message: victory_message)

      success_result(
        success: true,
        current_room: { id: room.slug, name: room.name, description: room.description },
        game_complete: true,
        ending: {
          type: 'good_ending',
          title: '¡ESCAPASTE!',
          description: session.ending_message,
          time_remaining_when_escaped: time_remaining
        }
      )
    end

    def add_direction_warning(result)
      if params[:direction] == GameConstants::Directions::SUR && @previous_room == GameConstants::Rooms::PASILLO
        result[:warning] = '¡ESTÁS YENDO EN LA DIRECCIÓN EQUIVOCADA!'
      end
    end

    def victory_message
      <<~MSG.squish
        Sales corriendo al jardín. Apenas cruzas el umbral, la mansión colapsa
        detrás de ti en una nube de polvo y escombros. El diario de María está
        a salvo en tus manos. Has escapado de la Mansión Velasco.
      MSG
    end
  end
end

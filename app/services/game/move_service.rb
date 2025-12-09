# frozen_string_literal: true

module Game
  class MoveService < BaseService
    attr_reader :direction

    def initialize(session, direction:)
      super(session)
      @direction = direction
    end

    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over

      exit_door = find_exit
      return { error: 'No hay salida en esa dirección.' } unless exit_door

      if exit_locked?(exit_door)
        return {
          success: false,
          message: 'La puerta está cerrada.',
          hint: exit_door.hint
        }
      end

      move_to_room(exit_door)
    end

    private

    def find_exit
      session.current_room.exits.find { |e| e.direction == direction }
    end

    def exit_locked?(exit_door)
      exit_door.locked && !session.door_unlocked?(exit_door.door_id)
    end

    def move_to_room(exit_door)
      target_room = Room.find_by_slug(exit_door.target_room_slug)

      # Check for victory
      if target_room.slug == 'salida'
        return process_victory(target_room)
      end

      previous_room = session.current_room_slug
      session.update!(current_room_slug: target_room.slug)

      result = {
        success: true,
        previous_room: previous_room,
        current_room: RoomSerializer.render_as_hash(target_room, session: session)
      }

      if session.panic?
        result[:panic] = panic_info
        # Warning if going wrong direction
        if direction == 'sur' && previous_room == 'pasillo'
          result[:warning] = '¡ESTÁS YENDO EN LA DIRECCIÓN EQUIVOCADA!'
        end
      end

      result
    end

    def process_victory(room)
      # Re-check game state before victory (in case panic expired during request)
      session.reload
      if session.lost?
        return {
          error: session.ending_message,
          game_over: true,
          ending: {
            type: 'bad_ending',
            title: '¡TIEMPO AGOTADO!',
            description: session.ending_message
          }
        }
      end

      # Save time remaining BEFORE changing state (panic_time_remaining returns nil if not in panic state)
      time_remaining = session.panic_time_remaining

      session.win!(message: victory_message)

      {
        success: true,
        current_room: {
          id: room.slug,
          name: room.name,
          description: room.description
        },
        game_complete: true,
        ending: {
          type: 'good_ending',
          title: '¡ESCAPASTE!',
          description: session.ending_message,
          time_remaining_when_escaped: time_remaining
        }
      }
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

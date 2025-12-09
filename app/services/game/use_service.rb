# frozen_string_literal: true

module Game
  class UseService < BaseService
    TRAPS = {
      %w[candelabro puerta_terminal] => 'Una flecha sale de la pared.',
      %w[candelabro caja_fuerte] => 'Un gas comienza a salir de las paredes.'
    }.freeze

    attr_reader :item_slug, :target_slug

    def initialize(session, item:, target:)
      super(session)
      @item_slug = item
      @target_slug = target
    end

    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over
      return { error: 'No tienes ese objeto.' } unless session.has_item?(item_slug)

      trap_result = check_trap
      return trap_result if trap_result

      process_use
    end

    private

    def check_trap
      trap_key = [item_slug, target_slug]
      trap_message = TRAPS[trap_key]
      return nil unless trap_message

      session.take_damage

      result = {
        success: false,
        message: "Intentas usar #{item_slug} en #{target_slug}. #{trap_message}",
        damage: true,
        lives_remaining: session.lives
      }

      if session.lost?
        result[:game_over] = true
        result[:ending] = { type: 'no_lives', message: session.ending_message }
      end

      result[:panic] = panic_info if session.panic?
      result
    end

    def process_use
      exit_door = find_exit_door
      return use_on_door(exit_door) if exit_door

      { error: 'No puedes usar eso aquí.' }
    end

    def find_exit_door
      session.current_room.exits.find { |e| e.door_id == target_slug }
    end

    def use_on_door(exit_door)
      return { error: 'Esa puerta ya está abierta.' } if session.door_unlocked?(exit_door.door_id)
      return { error: 'Eso no funciona aquí.' } unless exit_door.required_item == item_slug

      session.unlock_door(exit_door.door_id)
      session.remove_from_inventory(item_slug)

      result = {
        success: true,
        message: 'La llave encaja perfectamente. La puerta se abre.',
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
  end
end

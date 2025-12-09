# frozen_string_literal: true

module Commands
  # Comando para usar un item en un objetivo (incluye lógica de trampas)
  # Unifica la lógica que estaba duplicada en UseService
  class UseCommand < BaseCommand
    # Strategy Pattern: Trampas definidas como datos, fácil de extender
    TRAPS = {
      %w[candelabro puerta_terminal] => 'Una flecha sale de la pared.',
      %w[candelabro caja_fuerte] => 'Un gas comienza a salir de las paredes.'
    }.freeze

    private

    def perform
      return item_not_found unless session.has_item?(item_slug)

      trap_result = check_trap
      return trap_result if trap_result

      process_use
    end

    def item_slug
      params[:item]
    end

    def target_slug
      params[:target]
    end

    def item_not_found
      error_result('No tienes ese objeto.')
    end

    def check_trap
      trap_key = [item_slug, target_slug]
      trap_message = TRAPS[trap_key]
      return nil unless trap_message

      session.take_damage
      build_trap_result(trap_message)
    end

    def build_trap_result(trap_message)
      result = {
        success: false,
        message: "Intentas usar #{item_slug} en #{target_slug}. #{trap_message}",
        damage: true,
        lives_remaining: session.lives
      }

      if session.lost?
        result[:game_over] = true
        result[:ending] = build_ending
      end

      result[:panic] = panic_info if session.panic?
      result
    end

    def process_use
      exit_door = find_exit_door
      return use_on_exit_door(exit_door) if exit_door

      error_result('No puedes usar eso aquí.')
    end

    def find_exit_door
      session.current_room.exits.find { |e| e.door_id == target_slug }
    end

    def use_on_exit_door(exit_door)
      return error_result('Esa puerta ya está abierta.') if session.door_unlocked?(exit_door.door_id)
      return error_result('Eso no funciona aquí.') unless exit_door.required_item == item_slug

      session.unlock_door(exit_door.door_id)
      session.remove_from_inventory(item_slug)

      success_result(
        success: true,
        message: 'La llave encaja perfectamente. La puerta se abre.',
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

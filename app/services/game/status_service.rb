# frozen_string_literal: true

module Game
  class StatusService < BaseService
    def call
      check_panic_expired

      {
        game_id: session.id.to_s,
        status: session.status,
        lives: session.lives,
        current_room: session.current_room_slug,
        inventory_count: session.inventory.size,
        clues_count: session.collected_clues.size,
        terminal_attempts: session.terminal_attempts,
        has_vault_access: session.has_vault_token,
        panic: session.panic? ? panic_info : nil,
        game_over: session.lost? || session.won?,
        ending: session.lost? || session.won? ? {
          type: session.ending_type,
          message: session.ending_message
        } : nil
      }.compact
    end
  end
end

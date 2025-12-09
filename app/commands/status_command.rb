# frozen_string_literal: true

module Commands
  class StatusCommand < BaseCommand
    private

    def perform
      # Check panic but don't return error, just update state
      if session.panic? && session.panic_expired?
        session.lose!(
          ending: 'panic_timeout',
          message: 'El techo colapsa sobre ti. La Mansión Velasco se ha cobrado otra víctima.'
        )
      end

      build_status
    end

    def build_status
      result = {
        game_id: session.id.to_s,
        status: session.status,
        lives: session.lives,
        current_room: session.current_room_slug,
        inventory_count: session.inventory.size,
        clues_count: session.collected_clues.size,
        terminal_attempts: session.terminal_attempts,
        has_vault_access: session.has_vault_token,
        commands_executed: session.command_history.size
      }

      result[:panic] = panic_info if session.panic?
      result[:game_over] = true if session.lost? || session.won?
      result[:ending] = build_ending if session.lost? || session.won?

      result.compact
    end
  end
end

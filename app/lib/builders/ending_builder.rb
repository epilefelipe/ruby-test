# frozen_string_literal: true

# Single Responsibility: Solo construye datos de finales del juego
module Builders
  class EndingBuilder
    TITLES = {
      GameConstants::Endings::PANIC_TIMEOUT => '¡TIEMPO AGOTADO!',
      GameConstants::Endings::TERMINAL_BLOCKED => 'BLOQUEADO',
      GameConstants::Endings::NO_LIVES => 'SIN VIDAS',
      GameConstants::Endings::ESCAPED => '¡ESCAPASTE!'
    }.freeze

    DEFAULT_TITLE = 'GAME OVER'

    class << self
      def build(session)
        {
          type: session.ending_type,
          title: title_for(session.ending_type),
          description: session.ending_message
        }
      end

      def title_for(ending_type)
        TITLES.fetch(ending_type, DEFAULT_TITLE)
      end
    end
  end
end

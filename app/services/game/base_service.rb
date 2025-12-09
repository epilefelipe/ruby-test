# frozen_string_literal: true

module Game
  class BaseService
    attr_reader :session, :errors

    def initialize(session)
      @session = session
      @errors = []
    end

    def success?
      errors.empty?
    end

    def error(message)
      @errors << message
      false
    end

    private

    def check_game_over
      return unless session.lost?

      error(session.ending_message)
    end

    def check_panic_expired
      return unless session.panic? && session.panic_expired?

      session.lose!(
        ending: 'panic_timeout',
        message: 'El techo colapsa sobre ti. La Mansión Velasco se ha cobrado otra víctima.'
      )
      error(session.ending_message)
    end

    def panic_info
      return nil unless session.panic?

      {
        active: true,
        time_remaining: session.panic_time_remaining,
        message: panic_message
      }
    end

    def panic_message
      remaining = session.panic_time_remaining
      case remaining
      when 20..30 then "⚠️ ¡#{remaining} SEGUNDOS! ¡LA MANSIÓN COLAPSA!"
      when 10..19 then "⚠️ ¡#{remaining} SEGUNDOS! ¡CORRE!"
      when 1..9 then "⚠️ ¡#{remaining} SEGUNDOS! ¡AHORA O NUNCA!"
      else "⚠️ ¡TIEMPO AGOTADO!"
      end
    end
  end
end

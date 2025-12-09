# frozen_string_literal: true

module Commands
  # Template Method Pattern: Define el esqueleto del algoritmo de ejecución
  # Los comandos concretos implementan #perform
  #
  # Liskov Substitution Principle: BaseCommand NO define #undo
  # Solo los comandos que incluyen Undoable lo implementan
  class BaseCommand
    attr_reader :session, :params, :result, :executed_at

    def initialize(session, params = {})
      @session = session
      @params = params
      @result = nil
      @executed_at = nil
    end

    # Template Method: Esqueleto del algoritmo
    def execute
      return error_result('Sesión no válida') unless session

      if check_game_state
        @executed_at = Time.current
        @result = perform
        record_history
      end

      result
    end

    # Liskov Substitution: Por defecto NO es undoable
    def undoable?
      false
    end

    def command_name
      self.class.name.demodulize.underscore.gsub('_command', '')
    end

    protected

    def perform
      raise NotImplementedError, "#{self.class} debe implementar #perform"
    end

    def success_result(data = {})
      data[:panic] = panic_info if session.panic?
      data
    end

    def error_result(message, **options)
      { error: message }.merge(options)
    end

    def panic_info
      return nil unless session.panic?

      {
        active: true,
        time_remaining: session.panic_time_remaining,
        message: Builders::PanicMessageBuilder.build(session.panic_time_remaining)
      }
    end

    def build_ending
      Builders::EndingBuilder.build(session)
    end

    private

    def check_game_state
      if session.lost?
        @result = error_result(session.ending_message, game_over: true)
        return false
      end

      if session.panic? && session.panic_expired?
        session.lose!(
          ending: GameConstants::Endings::PANIC_TIMEOUT,
          message: I18n.t('game.endings.panic_timeout', default: 'El techo colapsa sobre ti. La Mansión Velasco se ha cobrado otra víctima.')
        )
        @result = error_result(session.ending_message, game_over: true, ending: build_ending)
        return false
      end

      true
    end

    def record_history
      return unless result && !result[:error]

      session.command_history << {
        command: command_name,
        params: params,
        executed_at: executed_at.iso8601,
        room: session.current_room_slug
      }
      session.save!
    end
  end
end

# frozen_string_literal: true

module Game
  class TerminalAuthService < BaseService
    attr_reader :password

    def initialize(session, password:)
      super(session)
      @password = password
    end

    def call
      return { error: errors.first, game_over: true } if check_game_over
      return { error: 'No hay terminal en esta habitación.' } unless in_terminal_room?
      return { error: 'Ya te has autenticado.' } if session.has_vault_token

      if correct_password?
        process_success
      else
        process_failure
      end
    end

    private

    def in_terminal_room?
      session.current_room_slug == 'estudio'
    end

    def correct_password?
      password == Settings.game.password
    end

    def process_success
      token = JwtService.encode({ level: 1, room: 'vault', game_id: session.id.to_s })

      session.update!(has_vault_token: true, vault_token: token)
      session.activate_panic!

      {
        success: true,
        message: 'ACCESO CONCEDIDO. Bienvenido, Dr. Velasco.',
        terminal_output: [
          'Sistema Velasco v2.1',
          'Último acceso: 15/10/1987',
          'Generando tarjeta de acceso...',
          '⚠️ ALERTA: Protocolo de seguridad activado',
          '⚠️ AUTODESTRUCCIÓN EN 30 SEGUNDOS'
        ],
        panic_mode: {
          activated: true,
          time_remaining: session.panic_time_remaining,
          message: '¡La mansión va a colapsar! Tienes 30 segundos para escapar.'
        },
        access_token: token,
        item_received: {
          id: 'access_card_1',
          name: 'Tarjeta de Acceso Nivel 1',
          description: 'Tarjeta magnética. ¡DATE PRISA!'
        }
      }
    end

    def process_failure
      session.inc(terminal_attempts: 1)
      attempts_remaining = Settings.game.max_terminal_attempts - session.terminal_attempts

      if attempts_remaining <= 0
        session.lose!(
          ending: 'terminal_blocked',
          message: 'El sistema se ha bloqueado. Escuchas pasos acercándose. No hay escape.'
        )

        return {
          success: false,
          message: 'SISTEMA BLOQUEADO',
          game_over: true,
          ending: {
            type: 'bad_ending',
            title: 'Bloqueado',
            description: session.ending_message
          }
        }
      end

      {
        success: false,
        message: 'ACCESO DENEGADO',
        attempts_remaining: attempts_remaining,
        warning: "Advertencia: #{attempts_remaining} intentos restantes antes del bloqueo."
      }
    end
  end
end

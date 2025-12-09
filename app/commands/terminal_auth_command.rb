# frozen_string_literal: true

module Commands
  class TerminalAuthCommand < BaseCommand
    MAX_ATTEMPTS = 3

    private

    def perform
      return error_result('No hay terminal en esta habitación.') unless in_terminal_room?
      return error_result('Ya te has autenticado.') if session.has_vault_token

      if correct_password?
        process_success
      else
        process_failure
      end
    end

    def in_terminal_room?
      session.current_room_slug == 'estudio'
    end

    def correct_password?
      params[:password] == session.password
    end

    def process_success
      token = JwtService.encode({ level: 1, room: 'vault', game_id: session.id.to_s })

      session.update!(has_vault_token: true, vault_token: token)
      session.activate_panic!

      success_result(
        success: true,
        message: 'ACCESO CONCEDIDO. Bienvenido, Dr. Velasco.',
        terminal_output: terminal_messages,
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
      )
    end

    def process_failure
      session.inc(terminal_attempts: 1)
      attempts_remaining = MAX_ATTEMPTS - session.terminal_attempts

      if attempts_remaining <= 0
        session.lose!(
          ending: 'terminal_blocked',
          message: 'El sistema se ha bloqueado. Escuchas pasos acercándose. No hay escape.'
        )

        return error_result(
          'SISTEMA BLOQUEADO',
          game_over: true,
          ending: {
            type: 'bad_ending',
            title: 'Bloqueado',
            description: session.ending_message
          }
        )
      end

      success_result(
        success: false,
        message: 'ACCESO DENEGADO',
        attempts_remaining: attempts_remaining,
        warning: "Advertencia: #{attempts_remaining} intentos restantes antes del bloqueo."
      )
    end

    def terminal_messages
      [
        'Sistema Velasco v2.1',
        'Último acceso: 15/10/1987',
        'Generando tarjeta de acceso...',
        '⚠️ ALERTA: Protocolo de seguridad activado',
        '⚠️ AUTODESTRUCCIÓN EN 30 SEGUNDOS'
      ]
    end
  end
end

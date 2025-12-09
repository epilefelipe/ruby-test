# frozen_string_literal: true

module Game
  class VaultService < BaseService
    attr_reader :token

    def initialize(session, token:)
      super(session)
      @token = token
    end

    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over
      return error_response('No hay caja fuerte en esta habitación.') unless in_vault_room?
      return error_response('Acceso denegado. Necesitas una tarjeta de acceso.', 401) unless token.present?
      return error_response('Token inválido o expirado.', 403) unless valid_token?

      process_open
    end

    private

    def in_vault_room?
      session.current_room_slug == 'estudio'
    end

    def valid_token?
      token == session.vault_token && JwtService.valid?(token)
    end

    def error_response(message, status = nil)
      result = { success: false, error: message }
      result[:status] = status if status
      result
    end

    def process_open
      # Add items to inventory
      session.add_to_inventory('llave_maestra')
      session.add_to_inventory('diario_maria')

      # Add final clue
      session.add_clue('clue_escape')

      result = {
        success: true,
        message: 'La caja fuerte se abre con un clic.',
        vault_contents: {
          description: 'Dentro encuentras documentos antiguos y una llave maestra.',
          items_found: [
            {
              id: 'llave_maestra',
              name: 'Llave Maestra',
              description: 'Una llave dorada con el emblema Velasco. Abre la puerta principal.',
              added_to_inventory: true
            },
            {
              id: 'diario_maria',
              name: 'Diario de María',
              description: 'El diario personal de María Velasco.',
              added_to_inventory: true
            }
          ]
        },
        clue_discovered: {
          id: 'clue_escape',
          text: 'El diario dice: "La salida está al norte del pasillo."'
        }
      }

      result[:panic] = panic_info if session.panic?
      result
    end
  end
end

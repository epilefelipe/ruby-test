# frozen_string_literal: true

module Commands
  class VaultOpenCommand < BaseCommand
    private

    def perform
      return error_result('No hay caja fuerte en esta habitación.') unless in_vault_room?
      return error_result('Acceso denegado. Necesitas una tarjeta de acceso.', status: 401) unless params[:token].present?
      return error_result('Token inválido o expirado.', status: 403) unless valid_token?

      process_open
    end

    def in_vault_room?
      session.current_room_slug == 'estudio'
    end

    def valid_token?
      params[:token] == session.vault_token && JwtService.valid?(params[:token])
    end

    def process_open
      session.add_to_inventory('llave_maestra')
      session.add_to_inventory('diario_maria')
      session.add_clue('clue_escape')

      success_result(
        success: true,
        message: 'La caja fuerte se abre con un clic.',
        vault_contents: {
          description: 'Dentro encuentras documentos antiguos y una llave maestra.',
          items_found: vault_items
        },
        clue_discovered: {
          id: 'clue_escape',
          text: 'El diario dice: "La salida está al norte del pasillo."'
        }
      )
    end

    def vault_items
      [
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
    end
  end
end

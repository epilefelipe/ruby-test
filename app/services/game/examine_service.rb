# frozen_string_literal: true

module Game
  class ExamineService < BaseService
    attr_reader :target

    def initialize(session, target:)
      super(session)
      @target = target
    end

    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over

      item = find_item
      return { error: 'No encuentras eso aquí.' } unless item

      session.mark_examined(item.slug)
      result = build_result(item)
      result[:panic] = panic_info if session.panic?
      result
    end

    private

    def find_item
      # Check room items or inventory
      room_item = session.current_room.items.find_by(slug: target)
      return room_item if room_item

      Item.find_by_slug(target) if session.has_item?(target)
    end

    def build_result(item)
      item_data = ItemSerializer.render_as_hash(item, view: :detailed)

      # Apply dynamic descriptions based on session data
      item_data[:description] = dynamic_description(item)

      result = { item: item_data }

      process_contained_items(item, result)
      process_clue(item, result)
      process_interaction(item, result)

      result
    end

    def dynamic_description(item)
      case item.slug
      when 'periodico'
        "Un periódico viejo. El titular dice: \"TRAGEDIA EN LA MANSIÓN VELASCO - 15 de Octubre de #{session.photo_year}\". Hay una foto de una niña llamada María."
      when 'cuadro_familia'
        "Una foto familiar. Padre, madre y una niña. Debajo dice: \"Familia Velasco, #{session.photo_year}\". María lleva un collar con el número #{session.birth_year}."
      when 'foto_escritorio'
        "María soplando velas. El pastel dice \"Felices #{session.age_in_photo}\". La fecha en el reverso: \"Octubre #{session.photo_year}\"."
      when 'nota_1'
        "Letra temblorosa: \"María nunca olvidó el año en que todo comenzó. La clave está en su nacimiento.\""
      when 'diario_maria'
        "Las páginas están amarillentas. La última entrada dice: \"15 de Octubre, #{session.photo_year} - Escucho ruidos abajo. Papá me dijo que me escondiera. Si lees esto, SAL DE AQUÍ.\""
      else
        item.description
      end
    end

    def process_contained_items(item, result)
      return if item.contains_items.blank?

      items_found = []
      item.contains_items.each do |item_slug|
        contained = Item.find_by_slug(item_slug)
        next unless contained&.pickable

        session.add_to_inventory(item_slug)
        items_found << {
          id: contained.slug,
          name: contained.name,
          added_to_inventory: true
        }
      end

      result[:items_found] = items_found if items_found.any?
    end

    def process_clue(item, result)
      return if item.reveals_clue.blank?

      clue = Clue.find_by_slug(item.reveals_clue)
      return unless clue

      session.add_clue(clue.slug)
      result[:clue_discovered] = {
        id: clue.slug,
        text: dynamic_clue_text(clue)
      }
    end

    def dynamic_clue_text(clue)
      case clue.slug
      when 'clue_year'
        "El año #{session.photo_year} parece importante. María Velasco tenía #{session.age_in_photo} años en la foto."
      when 'clue_birth'
        "Si María tenía #{session.age_in_photo} años en #{session.photo_year}... nació en #{session.birth_year}."
      when 'clue_collar'
        "El collar de María tiene grabado: #{session.birth_year}"
      when 'clue_birthday'
        "María cumplió #{session.age_in_photo} en #{session.photo_year}. Confirmado: nació en #{session.birth_year}."
      else
        clue.text
      end
    end

    def process_interaction(item, result)
      return if item.interaction_type.blank?

      result[:interaction_available] = {
        type: item.interaction_type,
        hint: interaction_hint(item.interaction_type)
      }
    end

    def interaction_hint(type)
      case type
      when 'terminal' then 'Usa POST /terminal/auth para ingresar la contraseña.'
      when 'vault' then 'Usa POST /vault/open con el token de acceso.'
      else nil
      end
    end
  end
end

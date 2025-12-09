# frozen_string_literal: true

module Game
  class InventoryService < BaseService
    def call
      return { error: errors.first, game_over: true } if check_panic_expired || check_game_over

      items = session.inventory.map do |slug|
        item = Item.find_by_slug(slug)
        next unless item

        ItemSerializer.render_as_hash(item, view: :inventory)
      end.compact

      clues = session.collected_clues.map do |slug|
        clue = Clue.find_by_slug(slug)
        next unless clue

        { id: clue.slug, text: dynamic_clue_text(clue) }
      end.compact

      result = {
        items: items,
        clues_collected: clues
      }

      result[:panic] = panic_info if session.panic?
      result
    end

    private

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
  end
end

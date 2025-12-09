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
      result = {
        item: ItemSerializer.render_as_hash(item, view: :detailed)
      }

      process_contained_items(item, result)
      process_clue(item, result)
      process_interaction(item, result)

      result
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
        text: clue.text
      }
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

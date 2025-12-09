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

        { id: clue.slug, text: clue.text }
      end.compact

      result = {
        items: items,
        clues_collected: clues
      }

      result[:panic] = panic_info if session.panic?
      result
    end
  end
end

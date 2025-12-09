# frozen_string_literal: true

module Commands
  class InventoryCommand < BaseCommand
    private

    def perform
      items = session.inventory.filter_map do |slug|
        item = Item.find_by_slug(slug)
        ItemSerializer.render_as_hash(item, view: :inventory) if item
      end

      clues = session.collected_clues.filter_map do |slug|
        clue = Clue.find_by_slug(slug)
        { id: clue.slug, text: DynamicContent.clue_text(clue, session) } if clue
      end

      success_result(
        items: items,
        clues_collected: clues
      )
    end
  end
end

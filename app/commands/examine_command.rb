# frozen_string_literal: true

module Commands
  class ExamineCommand < BaseCommand
    def undoable?
      true
    end

    def undo
      return unless @items_added

      @items_added.each do |item_slug|
        session.inventory.delete(item_slug)
      end
      session.examined_items.delete(params[:target])
      session.save!
    end

    private

    def perform
      @items_added = []
      item = find_item

      return error_result('No encuentras eso aquí.') unless item

      session.mark_examined(item.slug)
      build_result(item)
    end

    def find_item
      room_item = session.current_room.items.find_by(slug: params[:target])
      return room_item if room_item

      Item.find_by_slug(params[:target]) if session.has_item?(params[:target])
    end

    def build_result(item)
      item_data = ItemSerializer.render_as_hash(item, view: :detailed)
      item_data[:description] = DynamicContent.item_description(item, session)

      result = success_result(item: item_data)
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
        @items_added << item_slug
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
        text: DynamicContent.clue_text(clue, session)
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
      end
    end
  end
end

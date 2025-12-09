# frozen_string_literal: true

# Single Responsibility: Maneja toda la lógica de inventario
module Inventoriable
  extend ActiveSupport::Concern

  included do
    field :inventory, type: Array, default: []
  end

  def add_to_inventory(item_slug)
    return if has_item?(item_slug)

    inventory << item_slug
    save!
  end

  def remove_from_inventory(item_slug)
    inventory.delete(item_slug)
    save!
  end

  def has_item?(item_slug)
    inventory.include?(item_slug)
  end

  def inventory_empty?
    inventory.empty?
  end

  def inventory_count
    inventory.size
  end
end

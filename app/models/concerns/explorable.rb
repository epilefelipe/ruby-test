# frozen_string_literal: true

# Single Responsibility: Maneja el estado de exploración (pistas, items examinados, puertas)
module Explorable
  extend ActiveSupport::Concern

  included do
    field :collected_clues, type: Array, default: []
    field :unlocked_doors, type: Array, default: []
    field :examined_items, type: Array, default: []
  end

  # Pistas
  def add_clue(clue_slug)
    return if has_clue?(clue_slug)

    collected_clues << clue_slug
    save!
  end

  def has_clue?(clue_slug)
    collected_clues.include?(clue_slug)
  end

  # Puertas
  def unlock_door(door_id)
    return if door_unlocked?(door_id)

    unlocked_doors << door_id
    save!
  end

  def door_unlocked?(door_id)
    unlocked_doors.include?(door_id)
  end

  # Items examinados
  def mark_examined(item_slug)
    return if already_examined?(item_slug)

    examined_items << item_slug
    save!
  end

  def already_examined?(item_slug)
    examined_items.include?(item_slug)
  end
end

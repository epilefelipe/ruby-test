# frozen_string_literal: true

class GameSession
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  field :current_room_slug, type: String, default: 'cellar'
  field :lives, type: Integer, default: -> { Settings.game.lives }
  field :inventory, type: Array, default: []
  field :collected_clues, type: Array, default: []
  field :unlocked_doors, type: Array, default: []
  field :examined_items, type: Array, default: []
  field :terminal_attempts, type: Integer, default: 0
  field :has_vault_token, type: Boolean, default: false
  field :vault_token, type: String
  field :status, type: String, default: 'playing'
  field :panic_started_at, type: Time
  field :ending_type, type: String
  field :ending_message, type: String

  index({ created_at: -1 })

  aasm column: :status do
    state :playing, initial: true
    state :panic
    state :won
    state :lost

    event :activate_panic do
      transitions from: :playing, to: :panic, after: :set_panic_timer
    end

    event :win do
      transitions from: :panic, to: :won
    end

    event :lose do
      transitions from: %i[playing panic], to: :lost
    end
  end

  def current_room
    Room.find_by_slug(current_room_slug)
  end

  def panic_time_remaining
    return nil unless panic?
    return 0 if panic_expired?

    remaining = Settings.game.panic_duration - (Time.current - panic_started_at).to_i
    [remaining, 0].max
  end

  def panic_expired?
    return false unless panic?

    (Time.current - panic_started_at).to_i >= Settings.game.panic_duration
  end

  def add_to_inventory(item_slug)
    inventory << item_slug unless inventory.include?(item_slug)
    save!
  end

  def remove_from_inventory(item_slug)
    inventory.delete(item_slug)
    save!
  end

  def has_item?(item_slug)
    inventory.include?(item_slug)
  end

  def add_clue(clue_slug)
    collected_clues << clue_slug unless collected_clues.include?(clue_slug)
    save!
  end

  def unlock_door(door_id)
    unlocked_doors << door_id unless unlocked_doors.include?(door_id)
    save!
  end

  def door_unlocked?(door_id)
    unlocked_doors.include?(door_id)
  end

  def mark_examined(item_slug)
    examined_items << item_slug unless examined_items.include?(item_slug)
    save!
  end

  def already_examined?(item_slug)
    examined_items.include?(item_slug)
  end

  def take_damage
    self.lives -= 1
    save!
    lose!(ending: 'no_lives', message: 'Tus heridas son demasiado graves.') if lives <= 0
  end

  def lose!(ending:, message:)
    self.ending_type = ending
    self.ending_message = message
    self.lose
    save!
  end

  def win!(message:)
    self.ending_type = 'escaped'
    self.ending_message = message
    self.win
    save!
  end

  private

  def set_panic_timer
    self.panic_started_at = Time.current
  end
end

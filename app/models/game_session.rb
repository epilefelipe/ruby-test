# frozen_string_literal: true

# GameSession: Modelo principal del juego
# SRP: Las responsabilidades están delegadas a concerns específicos
class GameSession
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  # Concerns - Single Responsibility Principle
  include Inventoriable      # Manejo de inventario
  include Explorable         # Pistas, puertas, items examinados
  include Panicable          # Modo pánico
  include PasswordGenerator  # Generación de contraseña

  # Room state
  field :current_room_slug, type: String, default: GameConstants::Rooms::CELLAR
  field :lives, type: Integer, default: -> { Settings.game.lives }

  # Terminal and vault
  field :terminal_attempts, type: Integer, default: 0
  field :has_vault_token, type: Boolean, default: false
  field :vault_token, type: String

  # Game state
  field :status, type: String, default: 'playing'
  field :ending_type, type: String
  field :ending_message, type: String

  # Command history (Command Pattern)
  field :command_history, type: Array, default: []

  # Validations
  validates :current_room_slug, presence: true
  validates :lives, numericality: { greater_than_or_equal_to: 0 }
  validates :terminal_attempts, numericality: { greater_than_or_equal_to: 0 }

  # Indexes
  index({ created_at: -1 })
  index({ status: 1 })

  # State Machine (State Pattern)
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

  # Room navigation
  def current_room
    Room.find_by_slug(current_room_slug)
  end

  def move_to(room_slug)
    self.current_room_slug = room_slug
    save!
  end

  # Combat/Damage
  def take_damage
    self.lives -= 1
    save!
    lose!(ending: GameConstants::Endings::NO_LIVES, message: 'Tus heridas son demasiado graves.') if lives <= 0
  end

  def alive?
    lives.positive?
  end

  # Game endings
  def lose!(ending:, message:)
    self.ending_type = ending
    self.ending_message = message
    lose
    save!
  end

  def win!(message:)
    self.ending_type = GameConstants::Endings::ESCAPED
    self.ending_message = message
    win
    save!
  end

  def game_over?
    won? || lost?
  end

  # Terminal
  def increment_terminal_attempts
    self.terminal_attempts += 1
    save!
  end

  def terminal_blocked?
    terminal_attempts >= Settings.game.max_terminal_attempts
  end

  # Vault token
  def grant_vault_token(token)
    self.has_vault_token = true
    self.vault_token = token
    save!
  end
end

# frozen_string_literal: true

# Centralized constants to avoid magic numbers and strings
module GameConstants
  # Directions as array (for validation)
  DIRECTIONS = %w[norte sur este oeste].freeze

  # Direction constants (for comparison)
  module Directions
    NORTE = 'norte'
    SUR = 'sur'
    ESTE = 'este'
    OESTE = 'oeste'
  end

  # Room slugs
  module Rooms
    CELLAR = 'cellar'
    PASILLO = 'pasillo'
    ESTUDIO = 'estudio'
    SALIDA = 'salida'
    ALL = [CELLAR, PASILLO, ESTUDIO, SALIDA].freeze
  end

  # Item interaction types
  module Interactions
    TERMINAL = 'terminal'
    VAULT = 'vault'
    DOOR = 'door'
    ALL = [TERMINAL, VAULT, DOOR].freeze
  end

  # Game endings
  module Endings
    ESCAPED = 'escaped'
    PANIC_TIMEOUT = 'panic_timeout'
    TERMINAL_BLOCKED = 'terminal_blocked'
    NO_LIVES = 'no_lives'

    GOOD = [ESCAPED].freeze
    BAD = [PANIC_TIMEOUT, TERMINAL_BLOCKED, NO_LIVES].freeze
  end

  # Password generation
  module Password
    BIRTH_YEAR_RANGE = (1970..1995).freeze
    AGE_RANGE = (5..12).freeze
  end

  # Default values
  module Defaults
    LIVES = 3
    MAX_TERMINAL_ATTEMPTS = 3
    PANIC_DURATION = 30
  end
end

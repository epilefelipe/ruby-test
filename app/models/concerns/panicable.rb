# frozen_string_literal: true

# Single Responsibility: Maneja toda la lógica del modo pánico
module Panicable
  extend ActiveSupport::Concern

  included do
    field :panic_started_at, type: Time
  end

  def panic_time_remaining
    return nil unless panic?
    return 0 if panic_expired?

    remaining = panic_duration - elapsed_panic_time
    [remaining, 0].max
  end

  def panic_expired?
    return false unless panic?

    elapsed_panic_time >= panic_duration
  end

  private

  def elapsed_panic_time
    (Time.current - panic_started_at).to_i
  end

  def panic_duration
    Settings.game.panic_duration
  end

  def set_panic_timer
    self.panic_started_at = Time.current
  end
end

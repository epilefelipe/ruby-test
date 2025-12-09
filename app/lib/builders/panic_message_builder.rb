# frozen_string_literal: true

# Single Responsibility: Solo construye mensajes de pánico
module Builders
  class PanicMessageBuilder
    THRESHOLDS = [
      { range: 20..30, template: "⚠️ ¡%d SEGUNDOS! ¡LA MANSIÓN COLAPSA!" },
      { range: 10..19, template: "⚠️ ¡%d SEGUNDOS! ¡CORRE!" },
      { range: 1..9,   template: "⚠️ ¡%d SEGUNDOS! ¡AHORA O NUNCA!" }
    ].freeze

    DEFAULT_MESSAGE = '⚠️ ¡TIEMPO AGOTADO!'

    class << self
      def build(time_remaining)
        return DEFAULT_MESSAGE unless time_remaining&.positive?

        threshold = THRESHOLDS.find { |t| t[:range].cover?(time_remaining) }
        threshold ? format(threshold[:template], time_remaining) : DEFAULT_MESSAGE
      end
    end
  end
end

# frozen_string_literal: true

class JwtService
  class << self
    def encode(payload)
      JWT.encode(
        payload.merge(exp: Settings.game.panic_duration.seconds.from_now.to_i),
        secret_key,
        'HS256'
      )
    end

    def decode(token)
      decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
      decoded.first
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def valid?(token)
      decode(token).present?
    end

    private

    def secret_key
      Settings.jwt.secret_key
    end
  end
end

# frozen_string_literal: true

# Custom inflections for Zeitwerk autoloader
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'jwt_service' => 'JwtService'
  )
end

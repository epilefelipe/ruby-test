# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'action_controller/railtie'

Bundler.require(*Rails.groups)

module MansionVelasco
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    config.autoload_paths += %W[
      #{config.root}/app/services
      #{config.root}/app/serializers
    ]

    config.generators do |g|
      g.orm :mongoid
    end
  end
end

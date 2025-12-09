# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'action_controller/railtie'

Bundler.require(*Rails.groups)

# Define namespaces early for Zeitwerk
module Commands; end
module Game; end
module Builders; end

module MansionVelasco
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    # Autoload paths for custom directories
    config.autoload_lib(ignore: %w[assets tasks])

    %w[services serializers lib].each do |dir|
      config.autoload_paths << "#{config.root}/app/#{dir}"
      config.eager_load_paths << "#{config.root}/app/#{dir}"
    end

    # Commands namespace - collapse the commands directory
    initializer 'configure_commands_autoload', before: :set_autoload_paths do
      Rails.autoloaders.main.push_dir("#{config.root}/app/commands", namespace: Commands)
    end

    config.generators do |g|
      g.orm :mongoid
    end
  end
end

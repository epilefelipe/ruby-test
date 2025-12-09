# frozen_string_literal: true

require 'faraday'
require 'json'

module MansionVelasco
  class ApiClient
    attr_reader :base_url, :game_id, :vault_token

    def initialize(base_url: nil)
      @base_url = base_url || ENV.fetch('API_URL', 'http://localhost:3000')
      @game_id = nil
      @vault_token = nil
    end

    def start_game
      response = post('/api/v1/game/start')
      @game_id = response['game_id'] if response['game_id']
      response
    end

    def look
      get('/api/v1/game/look')
    end

    def inventory
      get('/api/v1/game/inventory')
    end

    def status
      get('/api/v1/game/status')
    end

    def clues
      get('/api/v1/game/clues')
    end

    def examine(target)
      post('/api/v1/game/examine', { target: target })
    end

    def use(item, target)
      post('/api/v1/game/use', { item: item, target: target })
    end

    def use_on_door(item, direction)
      post('/api/v1/game/use_on_door', { item: item, direction: direction })
    end

    def move(direction)
      post('/api/v1/game/move', { direction: direction })
    end

    def terminal_auth(password)
      response = post('/api/v1/terminal/auth', { password: password })
      @vault_token = response['access_token'] if response['access_token']
      response
    end

    def vault_open
      post('/api/v1/vault/open', {}, with_vault_token: true)
    end

    private

    def connection
      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def get(path)
      response = connection.get(path) do |req|
        req.headers['X-Game-ID'] = game_id if game_id
      end
      handle_response(response)
    end

    def post(path, body = {}, with_vault_token: false)
      response = connection.post(path) do |req|
        req.headers['X-Game-ID'] = game_id if game_id
        req.headers['Authorization'] = "Bearer #{vault_token}" if with_vault_token && vault_token
        req.body = body
      end
      handle_response(response)
    end

    def handle_response(response)
      response.body
    rescue StandardError => e
      { 'error' => e.message }
    end
  end
end

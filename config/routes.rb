# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Game endpoints
      post 'game/start', to: 'game#start'
      get 'game/look', to: 'game#look'
      get 'game/inventory', to: 'game#inventory'
      get 'game/clues', to: 'game#clues'
      get 'game/status', to: 'game#status'
      post 'game/examine', to: 'game#examine'
      post 'game/use', to: 'game#use'
      post 'game/use_on_door', to: 'game#use_on_door'
      post 'game/move', to: 'game#move'

      # Terminal authentication (in-game)
      post 'terminal/auth', to: 'terminal#auth'

      # Vault (requires JWT)
      post 'vault/open', to: 'vault#open'
    end
  end
end

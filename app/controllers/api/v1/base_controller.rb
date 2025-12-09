# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :set_game_session

      private

      def set_game_session
        game_id = request.headers['X-Game-ID'] || params[:game_id]
        @session = GameSession.find(game_id) if game_id.present?
      rescue Mongoid::Errors::DocumentNotFound
        render json: { error: 'Sesión de juego no encontrada. Usa POST /api/v1/game/start' }, status: :not_found
      end

      def require_session!
        return if @session.present?

        render json: { error: 'Se requiere X-Game-ID header o game_id param' }, status: :unauthorized
      end
    end
  end
end

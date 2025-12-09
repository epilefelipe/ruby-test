# frozen_string_literal: true

module Api
  module V1
    class TerminalController < BaseController
      before_action :require_session!

      def auth
        result = Game::TerminalAuthService.new(@session, password: params.require(:password)).call
        status = result[:game_over] ? :forbidden : :ok
        render json: result, status: status
      end
    end
  end
end

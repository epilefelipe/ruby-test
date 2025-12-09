# frozen_string_literal: true

module Api
  module V1
    class VaultController < BaseController
      before_action :require_session!

      def open
        command = Commands::CommandFactory.create(:vault_open, @session, token: extract_token)
        result = command.execute

        status = case result[:status]
                 when 401 then :unauthorized
                 when 403 then :forbidden
                 else :ok
                 end

        render json: result.except(:status), status: status
      end

      private

      def extract_token
        auth_header = request.headers['Authorization']
        return nil unless auth_header&.start_with?('Bearer ')

        auth_header.split(' ').last
      end
    end
  end
end

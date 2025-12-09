# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from Mongoid::Errors::DocumentNotFound, with: :handle_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from ArgumentError, with: :handle_argument_error
  end

  private

  def handle_standard_error(error)
    Rails.logger.error("#{error.class}: #{error.message}")
    Rails.logger.error(error.backtrace.first(10).join("\n"))

    render json: {
      error: 'Error interno del servidor',
      details: Rails.env.development? ? error.message : nil
    }.compact, status: :internal_server_error
  end

  def handle_not_found(error)
    render json: {
      error: 'Recurso no encontrado',
      details: error.message
    }, status: :not_found
  end

  def handle_parameter_missing(error)
    render json: {
      error: 'Parámetro requerido faltante',
      details: error.message
    }, status: :bad_request
  end

  def handle_argument_error(error)
    render json: {
      error: 'Argumento inválido',
      details: error.message
    }, status: :unprocessable_entity
  end
end

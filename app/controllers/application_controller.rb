# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    render json: { error: 'No encontrado' }, status: :not_found
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end

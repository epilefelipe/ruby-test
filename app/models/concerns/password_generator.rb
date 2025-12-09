# frozen_string_literal: true

# Single Responsibility: Genera y maneja la contraseña dinámica del juego
module PasswordGenerator
  extend ActiveSupport::Concern

  included do
    field :password, type: String
    field :birth_year, type: Integer
    field :photo_year, type: Integer
    field :age_in_photo, type: Integer

    before_create :generate_password
  end

  def correct_password?(attempt)
    password == attempt.to_s
  end

  private

  def generate_password
    self.birth_year = rand(GameConstants::Password::BIRTH_YEAR_RANGE)
    self.password = birth_year.to_s
    self.age_in_photo = rand(GameConstants::Password::AGE_RANGE)
    self.photo_year = birth_year + age_in_photo
  end
end

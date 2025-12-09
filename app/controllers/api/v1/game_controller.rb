# frozen_string_literal: true

module Api
  module V1
    class GameController < BaseController
      skip_before_action :set_game_session, only: [:start]
      before_action :require_session!, except: [:start]

      def start
        result = Game::StartService.new.call
        render json: result, status: :created
      end

      def look
        result = Game::LookService.new(@session).call
        render json: result
      end

      def inventory
        result = Game::InventoryService.new(@session).call
        render json: result
      end

      def clues
        clues = @session.collected_clues.map do |slug|
          clue = Clue.find_by_slug(slug)
          next unless clue

          { id: clue.slug, text: dynamic_clue_text(clue), source: clue.source }
        end.compact

        render json: { clues: clues }
      end

      def status
        result = Game::StatusService.new(@session).call
        render json: result
      end

      def examine
        result = Game::ExamineService.new(@session, target: params.require(:target)).call
        render json: result
      end

      def use
        result = Game::UseService.new(
          @session,
          item: params.require(:item),
          target: params.require(:target)
        ).call
        render json: result
      end

      def use_on_door
        result = Game::UseOnDoorService.new(
          @session,
          item: params.require(:item),
          direction: params.require(:direction)
        ).call
        render json: result
      end

      def move
        result = Game::MoveService.new(@session, direction: params.require(:direction)).call
        render json: result
      end

      private

      def dynamic_clue_text(clue)
        case clue.slug
        when 'clue_year'
          "El año #{@session.photo_year} parece importante. María Velasco tenía #{@session.age_in_photo} años en la foto."
        when 'clue_birth'
          "Si María tenía #{@session.age_in_photo} años en #{@session.photo_year}... nació en #{@session.birth_year}."
        when 'clue_collar'
          "El collar de María tiene grabado: #{@session.birth_year}"
        when 'clue_birthday'
          "María cumplió #{@session.age_in_photo} en #{@session.photo_year}. Confirmado: nació en #{@session.birth_year}."
        else
          clue.text
        end
      end
    end
  end
end

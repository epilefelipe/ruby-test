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
          { id: clue.slug, text: clue.text, source: clue.source } if clue
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
    end
  end
end

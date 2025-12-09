# frozen_string_literal: true

module Api
  module V1
    class GameController < BaseController
      skip_before_action :set_game_session, only: [:start]
      before_action :require_session!, except: [:start]

      def start
        session = GameSession.create!
        room = session.current_room

        render json: {
          game_id: session.id.to_s,
          player: { lives: session.lives, inventory: [] },
          current_room: RoomSerializer.render_as_hash(room, session: session),
          message: 'Bienvenido. Encuentra la salida antes de que sea tarde.'
        }, status: :created
      end

      def look
        execute_command(:look)
      end

      def inventory
        execute_command(:inventory)
      end

      def clues
        clues = @session.collected_clues.filter_map do |slug|
          clue = Clue.find_by_slug(slug)
          next unless clue

          { id: clue.slug, text: DynamicContent.clue_text(clue, @session), source: clue.source }
        end

        render json: { clues: clues }
      end

      def status
        execute_command(:status)
      end

      def examine
        execute_command(:examine, target: params.require(:target))
      end

      def use
        execute_command(:use, item: params.require(:item), target: params.require(:target))
      end

      def use_on_door
        execute_command(:use_on_door, item: params.require(:item), direction: params.require(:direction))
      end

      def move
        execute_command(:move, direction: params.require(:direction))
      end

      private

      def execute_command(action, params = {})
        command = Commands::CommandFactory.create(action, @session, params)
        result = command.execute
        render json: result
      end
    end
  end
end

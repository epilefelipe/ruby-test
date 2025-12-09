# frozen_string_literal: true

module Game
  class StartService
    def call
      session = GameSession.create!
      room = session.current_room

      {
        game_id: session.id.to_s,
        player: {
          lives: session.lives,
          inventory: []
        },
        current_room: RoomSerializer.render_as_hash(room, session: session),
        message: 'Bienvenido. Encuentra la salida antes de que sea tarde.'
      }
    end
  end
end

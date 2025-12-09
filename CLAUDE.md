# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**La Mansión Velasco** - Escape Room API game built with Rails 7.1 + MongoDB + AASM.

Players explore rooms, collect items/clues, solve puzzles, and must escape within 30 seconds after triggering the panic mode.

## Commands

```bash
# Start services
docker-compose up --build

# Run Rails commands
docker-compose exec web rails c
docker-compose exec web rails routes
docker-compose exec web rails db:seed

# Logs
docker-compose logs -f web

# Reset game data
docker-compose exec web rails db:seed
```

## Architecture

```
app/
├── controllers/api/v1/     # Versioned API endpoints
│   ├── base_controller.rb  # Session handling via X-Game-ID header
│   ├── game_controller.rb  # CRUD game actions
│   ├── terminal_controller.rb  # In-game auth (triggers panic)
│   └── vault_controller.rb # JWT-protected endpoint
├── models/
│   ├── game_session.rb     # Player state + AASM states
│   ├── room.rb             # Locations with embedded exits
│   ├── item.rb             # Objects (pickable, examinable)
│   └── clue.rb             # Discoverable hints
├── services/game/          # Business logic (one service per action)
│   ├── base_service.rb     # Shared panic/game-over checks
│   ├── start_service.rb
│   ├── look_service.rb
│   ├── examine_service.rb
│   ├── use_service.rb
│   ├── move_service.rb
│   ├── terminal_auth_service.rb  # Password validation + JWT
│   └── vault_service.rb    # Token-protected access
└── serializers/            # Blueprinter JSON serializers
```

## Configuration

All settings via environment variables (see `.env`):
- `GAME_LIVES`: Starting lives (default: 3)
- `GAME_PANIC_DURATION`: Seconds to escape (default: 30)
- `GAME_MAX_TERMINAL_ATTEMPTS`: Password attempts (default: 3)
- `JWT_SECRET_KEY`: For vault token generation

Settings gem loads from `config/settings.yml`.

## Game Flow

```
POST /game/start → game_id
     ↓
Explore (look, examine, use, move)
     ↓
Find password clues → "1980"
     ↓
POST /terminal/auth {password: "1980"}
     ↓
⚠️ PANIC MODE - 30 seconds ⚠️
     ↓
POST /vault/open (Bearer token) → master key
     ↓
Use key on door → move north → ESCAPE
```

## Key Patterns

- **Services**: All game logic in `app/services/game/`. Controllers are thin.
- **State Machine**: AASM in GameSession (playing → panic → won/lost)
- **JWT**: Generated on terminal auth, required for vault access
- **Panic Timer**: Server-side timestamp, checked on every request

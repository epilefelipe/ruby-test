# La Mansión Velasco - Escape Room API

Un juego de escape room basado en texto, construido con Rails 7.1 API y MongoDB.

## Descripción

Despiertas en el sótano de una mansión abandonada. Tu objetivo es encontrar pistas, resolver puzzles y escapar antes de que sea demasiado tarde. Cuando descubras la contraseña y la uses en el terminal, se activará el modo pánico: tendrás 30 segundos para escapar antes de que la mansión colapse.

## Tecnologías

- **Backend:** Rails 7.1 (API mode)
- **Base de datos:** MongoDB (Mongoid ODM)
- **Cache:** Redis
- **Cliente CLI:** Ruby con TTY gems
- **Contenedores:** Docker & Docker Compose

## Requisitos

- Docker Desktop
- Git

## Instalación y Ejecución

### 1. Clonar el repositorio

```bash
git clone https://github.com/epilefelipe/ruby-test.git
cd ruby-test
```

### 2. Iniciar los servicios

```bash
docker-compose up -d
```

Esto levantará:
- MongoDB (puerto 27017)
- Redis (puerto 6379)
- Rails API (puerto 3000)

### 3. Ejecutar seeds (primera vez)

```bash
docker-compose exec web rails db:seed
```

### 4. Jugar

```bash
docker-compose --profile play run --rm cli
```

## Comandos útiles

```bash
# Ver logs del servidor
docker-compose logs -f web

# Reiniciar el servidor
docker-compose restart web

# Detener todos los servicios
docker-compose down

# Reconstruir después de cambios
docker-compose up -d --build web
docker-compose --profile play build cli
```

## API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/game/start` | Iniciar nueva partida |
| GET | `/api/v1/game/look` | Ver habitación actual |
| GET | `/api/v1/game/inventory` | Ver inventario |
| POST | `/api/v1/game/examine` | Examinar objeto |
| POST | `/api/v1/game/use` | Usar item en objeto |
| POST | `/api/v1/game/use_on_door` | Usar item en puerta |
| POST | `/api/v1/game/move` | Moverse a otra habitación |
| GET | `/api/v1/game/status` | Estado del juego |
| POST | `/api/v1/terminal/auth` | Autenticarse en terminal |
| POST | `/api/v1/vault/open` | Abrir caja fuerte |

## Estructura del Proyecto

```
├── app/
│   ├── controllers/api/v1/    # Controladores API
│   ├── models/                # Modelos Mongoid
│   ├── serializers/           # Blueprinter serializers
│   └── services/game/         # Lógica del juego
├── client/                    # Cliente CLI
│   ├── lib/mansion_velasco/   # Código del cliente
│   └── bin/play               # Ejecutable
├── config/                    # Configuración Rails
├── db/seeds.rb               # Datos iniciales del juego
├── docker-compose.yml        # Orquestación de contenedores
└── game_design/              # Diseño del juego (JSON)
```

## Cómo Jugar

1. **Explora** las habitaciones usando "Mirar alrededor"
2. **Examina** objetos para encontrar pistas e items
3. **Usa** items en objetos o puertas cerradas
4. **Encuentra** la contraseña oculta en las pistas
5. **Ve al Estudio** y autentícate en el terminal
6. **Escapa** antes de que se acabe el tiempo (30 segundos)

## Finales

- **Victoria:** Escapar por la puerta principal antes del colapso
- **Derrota por tiempo:** No escapar en 30 segundos
- **Derrota por bloqueo:** Fallar 3 veces la contraseña del terminal

## Licencia

MIT

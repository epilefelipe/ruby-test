# frozen_string_literal: true

require 'pastel'
require 'tty-box'
require 'tty-cursor'
require 'tty-screen'

module MansionVelasco
  class Renderer
    attr_reader :pastel, :cursor

    def initialize
      @pastel = Pastel.new
      @cursor = TTY::Cursor
    end

    def clear
      print cursor.clear_screen
      print cursor.move_to(0, 0)
    end

    def title
      puts pastel.red.bold('
    ╔═══════════════════════════════════════════════════════════╗
    ║           LA MANSIÓN VELASCO - ESCAPE ROOM API            ║
    ╚═══════════════════════════════════════════════════════════╝
      ')
    end

    def render_room(data)
      return render_error(data['error']) if data['error']

      room = data['room'] || data['current_room']
      return unless room

      box = TTY::Box.frame(
        width: 70,
        padding: 1,
        title: { top_left: pastel.cyan.bold(" #{room['name']} ") },
        border: :thick
      ) do
        description = room['description'] || ''
        wrap_text(description, 66)
      end

      puts box
      puts

      render_items(data['items']) if data['items']&.any?
      render_exits(data['exits']) if data['exits']
    end

    def render_items(items)
      return if items.empty?

      puts pastel.yellow.bold('  Objetos visibles:')
      items.each do |item|
        hint = item['hint'] ? pastel.dim(" - #{item['hint']}") : ''
        puts "    #{pastel.green('•')} #{item['name']}#{hint}"
      end
      puts
    end

    def render_exits(exits)
      return if exits.empty?

      puts pastel.yellow.bold('  Salidas:')
      exits.each do |exit_info|
        direction = exit_info['direction']
        destination = exit_info['destination']
        locked = exit_info['locked']
        hint = exit_info['hint']

        status = locked ? pastel.red('[CERRADA]') : pastel.green('[ABIERTA]')
        dest_text = destination ? " → #{destination}" : ''
        hint_text = hint ? pastel.dim(" - #{hint}") : ''
        puts "    #{pastel.cyan('→')} #{direction.capitalize}#{dest_text} #{status}#{hint_text}"
      end
      puts
    end

    def render_examine(data)
      return render_error(data['error']) if data['error']

      item = data['item']
      if item
        puts
        puts pastel.cyan.bold("  #{item['name']}")
        puts pastel.white("  #{item['description']}")
        puts
      end

      if data['items_found']&.any?
        puts pastel.green.bold('  ¡Encontraste objetos!')
        data['items_found'].each do |found|
          puts "    #{pastel.green('+')} #{found['name']} #{pastel.dim('(añadido al inventario)')}"
        end
        puts
      end

      if data['clue_discovered']
        puts pastel.yellow.bold('  ¡Nueva pista!')
        puts "    #{pastel.yellow('★')} #{data['clue_discovered']['text']}"
        puts
      end

      render_interaction(data['interaction_available']) if data['interaction_available']
      render_panic(data['panic']) if data['panic']
    end

    def render_interaction(interaction)
      puts pastel.magenta.bold('  Interacción disponible:')
      puts "    Tipo: #{interaction['type']}"
      puts "    #{pastel.dim(interaction['hint'])}" if interaction['hint']
      puts
    end

    def render_use(data)
      return render_error(data['error']) if data['error']

      if data['success']
        puts
        puts pastel.green.bold("  ✓ #{data['message']}")
        if data['new_exit_available']
          puts pastel.cyan("    Nueva salida: #{data['new_exit_available']['direction']} → #{data['new_exit_available']['room_id']}")
        end
      else
        puts pastel.red("  ✗ #{data['message']}")
        render_damage(data) if data['damage']
      end
      puts

      render_panic(data['panic']) if data['panic']
    end

    def render_move(data)
      return render_error(data['error']) if data['error']

      if data['game_complete']
        render_victory(data)
      elsif data['success']
        render_room(data)
      else
        puts pastel.red("  ✗ #{data['message']}")
        puts pastel.dim("    #{data['hint']}") if data['hint']
      end

      render_panic(data['panic']) if data['panic']
      render_warning(data['warning']) if data['warning']
    end

    def render_inventory(data)
      return render_error(data['error']) if data['error']

      puts
      puts pastel.yellow.bold('  ═══ INVENTARIO ═══')
      puts

      if data['items']&.any?
        data['items'].each do |item|
          puts "    #{pastel.green('•')} #{pastel.bold(item['name'])}"
          puts "      #{pastel.dim(item['description'])}" if item['description']
        end
      else
        puts pastel.dim('    (vacío)')
      end

      puts
      puts pastel.yellow.bold('  ═══ PISTAS ═══')
      puts

      if data['clues_collected']&.any?
        data['clues_collected'].each do |clue|
          puts "    #{pastel.yellow('★')} #{clue['text']}"
        end
      else
        puts pastel.dim('    (ninguna)')
      end
      puts

      render_panic(data['panic']) if data['panic']
    end

    def render_terminal_auth(data)
      return render_error(data['error']) if data['error']

      if data['success']
        puts
        data['terminal_output']&.each do |line|
          if line.include?('⚠️')
            puts pastel.red.bold("  #{line}")
          else
            puts pastel.green("  #{line}")
          end
          sleep(0.3)
        end
        puts
        puts pastel.red.bold('  ¡¡¡ PANIC MODE ACTIVADO !!!')
        puts pastel.yellow("  #{data['panic_mode']['message']}")
        puts
        puts pastel.cyan("  Token recibido: #{data['access_token'][0..30]}...")
        puts
      else
        puts pastel.red.bold("  #{data['message']}")
        if data['game_over']
          render_game_over(data['ending'])
        else
          puts pastel.yellow("  #{data['warning']}")
        end
      end
      puts
    end

    def render_vault(data)
      return render_error(data['error']) if data['error']

      if data['success']
        puts
        puts pastel.green.bold("  ✓ #{data['message']}")
        puts
        puts pastel.yellow("  #{data['vault_contents']['description']}")
        puts

        data['vault_contents']['items_found']&.each do |item|
          puts "    #{pastel.green('+')} #{pastel.bold(item['name'])}"
          puts "      #{pastel.dim(item['description'])}"
        end

        if data['clue_discovered']
          puts
          puts "    #{pastel.yellow('★')} #{data['clue_discovered']['text']}"
        end
      end
      puts

      render_panic(data['panic']) if data['panic']
    end

    def render_status(data)
      puts
      puts pastel.cyan.bold('  ═══ ESTADO DEL JUEGO ═══')
      puts
      puts "    Game ID: #{pastel.dim(data['game_id'])}"
      puts "    Estado: #{status_color(data['status'])}"
      puts "    Vidas: #{render_lives(data['lives'])}"
      puts "    Habitación: #{data['current_room']}"
      puts "    Items: #{data['inventory_count']} | Pistas: #{data['clues_count']}"
      puts "    Intentos terminal: #{data['terminal_attempts']}/3"
      puts "    Acceso vault: #{data['has_vault_access'] ? pastel.green('Sí') : pastel.red('No')}"
      puts

      render_panic(data['panic']) if data['panic']

      if data['game_over']
        puts pastel.red.bold('  ¡JUEGO TERMINADO!')
        puts "    #{data['ending']['message']}" if data['ending']
      end
      puts
    end

    def render_panic(panic)
      return unless panic && panic['active']

      remaining = panic['time_remaining']

      color = case remaining
              when 20..30 then :yellow
              when 10..19 then :red
              else :red
              end

      box = TTY::Box.frame(
        width: 50,
        padding: [0, 1],
        border: :thick,
        style: { border: { fg: color } }
      ) do
        "#{panic['message']}\n  Tiempo restante: #{remaining} segundos"
      end

      puts pastel.send(color).bold(box)
    end

    def render_victory(data)
      clear
      puts pastel.green.bold('
    ╔═══════════════════════════════════════════════════════════╗
    ║                    ¡¡¡ VICTORIA !!!                       ║
    ╚═══════════════════════════════════════════════════════════╝
      ')

      ending = data['ending']
      puts
      puts pastel.green.bold("  #{ending['title']}")
      puts
      puts pastel.white("  #{wrap_text(ending['description'], 60)}")
      puts
      puts pastel.cyan("  Tiempo restante al escapar: #{ending['time_remaining_when_escaped']} segundos")
      puts
    end

    def render_game_over(ending)
      clear
      puts pastel.red.bold('
    ╔═══════════════════════════════════════════════════════════╗
    ║                     GAME OVER                             ║
    ╚═══════════════════════════════════════════════════════════╝
      ')

      puts
      puts pastel.red.bold("  #{ending['title']}")
      puts
      puts pastel.white("  #{ending['description']}")
      puts
      puts pastel.yellow("  #{ending['hint']}") if ending['hint']
      puts
    end

    def render_error(message)
      puts
      puts pastel.red("  Error: #{message}")
      puts
    end

    def render_damage(data)
      puts pastel.red.bold("  ¡Perdiste una vida!")
      puts "  Vidas restantes: #{render_lives(data['lives_remaining'])}"
    end

    def render_warning(message)
      puts pastel.yellow.bold("  ⚠️ #{message}")
    end

    def render_help
      puts
      puts pastel.cyan.bold('  ═══ COMANDOS DISPONIBLES ═══')
      puts
      puts "    #{pastel.green('mirar')}              - Ver la habitación actual"
      puts "    #{pastel.green('examinar')} <objeto>  - Examinar un objeto"
      puts "    #{pastel.green('usar')} <item> <obj>  - Usar item en objeto"
      puts "    #{pastel.green('ir')} <dirección>     - Moverse (norte/sur/este/oeste)"
      puts "    #{pastel.green('inventario')}         - Ver inventario y pistas"
      puts "    #{pastel.green('estado')}             - Ver estado del juego"
      puts "    #{pastel.green('terminal')} <pass>    - Ingresar contraseña"
      puts "    #{pastel.green('vault')}              - Abrir caja fuerte (necesita token)"
      puts "    #{pastel.green('ayuda')}              - Mostrar esta ayuda"
      puts "    #{pastel.green('salir')}              - Salir del juego"
      puts
    end

    private

    def render_lives(count)
      hearts = '❤️ ' * count
      empty = '🖤 ' * (3 - count)
      "#{hearts}#{empty}"
    end

    def status_color(status)
      case status
      when 'playing' then pastel.green('Jugando')
      when 'panic' then pastel.red.bold('¡PÁNICO!')
      when 'won' then pastel.green.bold('¡Ganaste!')
      when 'lost' then pastel.red('Perdiste')
      else status
      end
    end

    def wrap_text(text, width)
      text.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip
    end
  end
end

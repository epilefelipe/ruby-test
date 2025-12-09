# frozen_string_literal: true

require 'tty-prompt'
require 'tty-spinner'

module MansionVelasco
  class Game
    attr_reader :client, :renderer, :prompt, :running

    def initialize(api_url: nil)
      @client = ApiClient.new(base_url: api_url)
      @renderer = Renderer.new
      @prompt = TTY::Prompt.new(symbols: { marker: '>' })
      @running = true
    end

    def start
      renderer.clear
      renderer.title

      spinner = TTY::Spinner.new('  [:spinner] Conectando con la mansión...', format: :dots)
      spinner.auto_spin

      result = client.start_game
      spinner.stop

      if result['error']
        renderer.render_error(result['error'])
        puts renderer.pastel.red('  No se pudo conectar. ¿Está el servidor corriendo?')
        puts renderer.pastel.dim('  Ejecuta: docker-compose up')
        return
      end

      puts
      puts renderer.pastel.green("  Partida iniciada: #{result['game_id']}")
      puts renderer.pastel.white("  #{result['message']}")
      puts

      renderer.render_room(result)

      game_loop
    end

    def game_loop
      while running
        show_main_menu
      end
    end

    def show_main_menu
      puts
      choices = [
        { name: '👁  Mirar alrededor', value: :look },
        { name: '🔍 Examinar objeto', value: :examine },
        { name: '🔧 Usar item', value: :use },
        { name: '🚪 Ir a otra habitación', value: :move },
        { name: '🎒 Ver inventario y pistas', value: :inventory },
        { name: '💻 Usar terminal (contraseña)', value: :terminal },
        { name: '🔐 Abrir caja fuerte', value: :vault },
        { name: '📊 Ver estado', value: :status },
        { name: '❌ Salir', value: :exit }
      ]

      action = prompt.select('¿Qué quieres hacer?', choices, per_page: 9)

      case action
      when :look then handle_look
      when :examine then handle_examine_menu
      when :use then handle_use_from_menu
      when :move then handle_move_menu
      when :inventory then handle_inventory
      when :terminal then handle_terminal_menu
      when :vault then handle_vault
      when :status then handle_status
      when :exit then handle_exit
      end
    end

    private

    def handle_look
      result = client.look
      return if check_game_over(result)
      renderer.render_room(result)
    end

    def handle_examine_menu
      # Primero obtenemos los items de la habitación
      result = client.look
      return if check_game_over(result)

      items = result['items'] || []

      if items.empty?
        puts renderer.pastel.dim('  No hay objetos para examinar aquí.')
        return
      end

      choices = items.map do |item|
        { name: "#{item['name']} - #{item['description']}", value: item['slug'] }
      end
      choices << { name: '← Volver', value: :back }

      selected = prompt.select('¿Qué quieres examinar?', choices, per_page: 10)

      return if selected == :back

      result = client.examine(selected)
      return if check_game_over(result)
      renderer.render_examine(result)
    end

    def handle_move_menu
      result = client.look
      return if check_game_over(result)

      exits = result['exits'] || []

      if exits.empty?
        puts renderer.pastel.red('  No hay salidas disponibles.')
        return
      end

      choices = exits.map do |exit_info|
        direction = exit_info['direction']
        destination = exit_info['destination']
        locked = exit_info['locked']

        label = if locked
          "🔒 #{direction.capitalize} → #{destination} (BLOQUEADO)"
        else
          "🚪 #{direction.capitalize} → #{destination}"
        end

        { name: label, value: direction, disabled: locked ? '(necesitas llave)' : false }
      end
      choices << { name: '← Volver', value: :back }

      selected = prompt.select('¿A dónde quieres ir?', choices, per_page: 6)

      return if selected == :back

      result = client.move(selected)

      if result['game_complete']
        renderer.render_victory(result)
        @running = false
        return
      end

      return if check_game_over(result)
      renderer.render_move(result)
    end

    def handle_inventory
      result = client.inventory
      return if check_game_over(result)
      renderer.render_inventory(result)

      # Si hay items, preguntar si quiere usar alguno
      items = result['inventory'] || []
      clues = result['clues'] || []

      if clues.any?
        puts
        puts renderer.pastel.yellow.bold('  ═══ PISTAS RECOLECTADAS ═══')
        puts
        clues.each do |clue|
          puts "    #{renderer.pastel.yellow('★')} #{clue['text']}"
        end
        puts
      end

      return if items.empty?

      if prompt.yes?('  ¿Quieres usar algún item?')
        handle_use_menu(items)
      end
    end

    def handle_use_from_menu
      # Obtener inventario
      inv_result = client.inventory
      items = inv_result['items'] || []

      if items.empty?
        puts renderer.pastel.yellow('  No tienes items en tu inventario.')
        return
      end

      item_choices = items.map do |item|
        { name: item['name'], value: item['slug'] }
      end
      item_choices << { name: '← Volver', value: :back }

      selected_item = prompt.select('¿Qué item quieres usar?', item_choices)
      return if selected_item == :back

      # Obtener objetos de la habitación Y puertas
      room = client.look
      room_items = room['items'] || []
      exits = room['exits'] || []

      target_choices = []

      # Agregar puertas cerradas como targets
      exits.each do |exit_info|
        if exit_info['locked']
          door_name = "🚪 Puerta #{exit_info['direction']} (#{exit_info['destination']})"
          target_choices << { name: door_name, value: exit_info['direction'] }
        end
      end

      # Agregar objetos de la habitación
      room_items.each do |item|
        target_choices << { name: "📦 #{item['name']}", value: item['slug'] }
      end

      if target_choices.empty?
        puts renderer.pastel.yellow('  No hay nada donde usar el item.')
        return
      end

      target_choices << { name: '← Volver', value: :back }

      selected_target = prompt.select('¿En qué quieres usar el item?', target_choices)
      return if selected_target == :back

      # Si es una dirección, buscar el door_id
      exit_info = exits.find { |e| e['direction'] == selected_target }
      if exit_info
        # Usar en la puerta - necesitamos enviar el door_id
        result = client.use_on_door(selected_item, selected_target)
      else
        result = client.use(selected_item, selected_target)
      end

      return if check_game_over(result)
      renderer.render_use(result)
    end

    def handle_use_menu(items)
      item_choices = items.map do |item|
        { name: item['name'], value: item['slug'] }
      end
      item_choices << { name: '← Volver', value: :back }

      selected_item = prompt.select('¿Qué item quieres usar?', item_choices)
      return if selected_item == :back

      # Obtener objetos de la habitación
      room = client.look
      room_items = room['items'] || []

      target_choices = room_items.map do |item|
        { name: item['name'], value: item['slug'] }
      end
      target_choices << { name: '← Volver', value: :back }

      selected_target = prompt.select('¿En qué objeto?', target_choices)
      return if selected_target == :back

      result = client.use(selected_item, selected_target)
      return if check_game_over(result)
      renderer.render_use(result)
    end

    def handle_terminal_menu
      puts
      puts renderer.pastel.cyan('  ╔════════════════════════════════════╗')
      puts renderer.pastel.cyan('  ║         TERMINAL DE ACCESO         ║')
      puts renderer.pastel.cyan('  ╚════════════════════════════════════╝')
      puts

      password = prompt.ask('  Ingresa la contraseña:') do |q|
        q.required true
      end

      spinner = TTY::Spinner.new('  [:spinner] Verificando...', format: :dots)
      spinner.auto_spin
      sleep(0.5)
      result = client.terminal_auth(password)
      spinner.stop

      return if check_game_over(result)
      renderer.render_terminal_auth(result)
    end

    def handle_vault
      unless client.vault_token
        puts renderer.pastel.red('  ⚠ No tienes token de acceso.')
        puts renderer.pastel.dim('  Primero autentícate en el terminal.')
        return
      end

      result = client.vault_open
      return if check_game_over(result)
      renderer.render_vault(result)
    end

    def handle_status
      result = client.status
      renderer.render_status(result)
    end

    def handle_exit
      if prompt.yes?(renderer.pastel.yellow('  ¿Seguro que quieres salir?'))
        puts renderer.pastel.dim('  ¡Hasta pronto!')
        @running = false
      end
    end

    def check_game_over(result)
      return false unless result['game_over']

      if result['ending']
        renderer.render_game_over(result['ending'])
      elsif result['error']
        # Fallback for game over without structured ending
        renderer.render_game_over({
          'type' => 'bad_ending',
          'title' => '¡GAME OVER!',
          'description' => result['error']
        })
      end

      if prompt.yes?(renderer.pastel.yellow('  ¿Jugar de nuevo?'))
        new_result = client.start_game
        renderer.clear
        renderer.title
        renderer.render_room(new_result)
      else
        @running = false
      end

      true
    end
  end
end

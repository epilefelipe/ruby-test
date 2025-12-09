# frozen_string_literal: true

module Commands
  class CommandFactory
    COMMAND_MAP = {
      look: LookCommand,
      examine: ExamineCommand,
      move: MoveCommand,
      inventory: InventoryCommand,
      use: UseCommand,
      use_on_door: UseOnDoorCommand,
      terminal_auth: TerminalAuthCommand,
      vault_open: VaultOpenCommand,
      status: StatusCommand
    }.freeze

    class << self
      def create(action, session, params = {})
        command_class = COMMAND_MAP[action.to_sym]
        raise ArgumentError, "Comando desconocido: #{action}" unless command_class

        command_class.new(session, params)
      end

      def available_commands
        COMMAND_MAP.keys
      end

      def command_for(action)
        COMMAND_MAP[action.to_sym]
      end
    end
  end
end

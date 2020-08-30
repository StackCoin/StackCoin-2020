class StackCoin::Bot::Commands
  class Help < Command
    getter trigger = "help"
    getter aliases = ["what"]
    getter usage = "<?command>"
    getter desc = "Descriptions and usage of every StackCoin command"

    property root_help = Discord::Embed.new
    property sub_help = {} of String => Discord::Embed

    def initialize(all_commands)
      all_fields = [] of Discord::EmbedField
      all_commands.each_value do |command|
        if command.usage
          name = "#{command.trigger} - #{command.usage}"
        else
          name = "#{command.trigger}"
        end

        command_field = Discord::EmbedField.new(
          name: "#{name}",
          value: command.desc
        )

        @sub_help[command.trigger] = Discord::Embed.new(
          title: "Help: #{command.trigger}",
          fields: [command_field]
        )

        all_fields << command_field
      end

      @root_help = Discord::Embed.new(title: "Help:", fields: all_fields)
    end

    def invoke(message, parsed)
      if parsed.arguments.size >= 1
        command = parsed.arguments[0].to_s

        if @sub_help.has_key? command
          send_embed(message, @sub_help[command])
        else
          potential = Levenshtein.find(command, @sub_help.keys)
          if potential
            postfix = ", did you mean #{potential}?"
          end

          send_message(message, "Unknown help section: #{command}#{postfix}")
        end
      else
        send_message(message, @root_help)
      end
    end
  end
end

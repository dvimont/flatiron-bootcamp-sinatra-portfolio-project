class CliController

  def initialize(catalog_size=CatalogBuilder.default_catalog_size)
    puts "PLEASE WAIT WHILE AUDIOBOOK CATALOG IS INITIALIZED!!"
    puts ""
    CatalogBuilder.build(catalog_size)
  end

  SCROLL_SIZE = 10
  PROMPT = ">> "
  MORE_PROMPT = "MORE >> "
  HORIZONTAL_LINE = "\n======================================================"
  REINPUT_REQUEST = "Sorry, I didn't recognize your command!\nPlease note the command options above, and try again!!"
  EXIT_COMMANDS = ["exit", "quit", "q", "x", "0"]

  def start
    input = ""
    puts "#{HORIZONTAL_LINE}\nWelcome to Librivox Explorer's COMMAND LINE INTERFACE!#{HORIZONTAL_LINE}".cyan
    invalid_input = false
    until EXIT_COMMANDS.include?(input)
      if invalid_input
        puts REINPUT_REQUEST.red
      else
        puts  "  ::MAIN MENU::"
        puts  "  Please select one of the following commands by its number:\n" +
              "    ---------\n" +
              "    1 -- browse by Librivox Genre (#{GenreLibrivox.all.size.to_s})\n" +
              "    2 -- browse by Gutenberg Genre (#{GenreGutenberg.all.size.to_s})\n" +
              "    3 -- browse by Author (#{Author.all.size.to_s})\n" +
              "    4 -- browse by Reader (#{Reader.all.size.to_s})\n" +
              "    ---------\n" +
              "    0 -- EXIT".green
        puts ""
      end

      invalid_input = false
      print PROMPT; input = gets.strip

      case input
      when "1"
        browse_by_category(GenreLibrivox)
      when "2"
        browse_by_category(GenreGutenberg)
      when "3"
        browse_by_category(Author)
      when "4"
        browse_by_category(Reader)
      else
        if EXIT_COMMANDS.include?(input)
          puts "\nThanks for visiting Librivox Explorer's CLI. Your session is completed!!"
          puts ""
        else
          invalid_input = true
        end
      end
    end
  end

  def browse_by_category(category_type)
    input = ""
    invalid_input = false
    until EXIT_COMMANDS.include?(input)
      if invalid_input
        puts REINPUT_REQUEST.red
      else
        puts "  ::BROWSING BY #{category_type.to_s.upcase}::"
        puts "  Please enter a name prefix to scroll through " +
                    "#{category_type.to_s}s with name beginning with it...\n" +
             "    ---------\n" +
             "    0 -- return to MAIN MENU".green
        puts ""
      end

      invalid_input = false
      print PROMPT; input = gets.strip

      if input != "0"
        self.browse_by_category_subset(category_type, input)
      end
    end
  end

  def browse_by_category_subset(category_type, name_prefix)
    category_array = category_type.all_by_name.values_with_key_prefix(name_prefix.upcase)
    if category_array.size == 0
      puts "   No #{category_type.to_s}s found with surname prefix of '#{name_prefix}'.\n".red +
           "     Press ENTER to return to menu...".red
      gets
      return
    end
    counter = 0
    category_array.each {|category_object|
      counter += 1
      puts "   #{counter.to_s}: #{category_object.to_s}"
      if counter == category_array.size
        puts "END of current list. Enter number to list #{category_type.to_s}'s audiobooks; " +
                "ENTER to return to menu."
        print CliController::PROMPT; input = gets.strip
      elsif counter % SCROLL_SIZE == 0
        puts "Enter number to list #{category_type.to_s}'s audiobooks; " +
                    "ENTER to continue scrolling; 0 to return to menu."
        print CliController::MORE_PROMPT; input = gets.strip
      end
      return if input == "0" || list_audiobooks(input, category_array)
    }
  end

  def list_audiobooks(input, category_array)
    selected_item_number = input.to_i
    return false if selected_item_number.to_s != input # i.e. if input was not numeric!
    return false if !selected_item_number.between?(1, category_array.size)
    category_object = category_array[selected_item_number - 1]
    list_size = category_object.audiobooks_by_title.size
    puts ""
    puts "   Audiobooks (by title) belonging to #{category_object.class.to_s}: #{category_object.to_s.green}" +
          " (#{list_size.to_s})"
    puts "   --------------------------------------------"
    category_object.audiobooks_by_title.values.each.with_index(1) {|audiobook, i|
      puts "      #{i.to_s}: #{audiobook.title.cyan}\n" +
              "         URL: #{audiobook.url_librivox.cyan}"
      input = nil
      if i == list_size
        puts "   All audiobooks have been displayed; enter number to open in browser; ENTER to return to menu."
        print PROMPT; input = gets.strip
      elsif i % CliController::SCROLL_SIZE == 0
        puts "#{i.to_s} of #{list_size.to_s} displayed.\n" +
            "Enter number to open in browser; ENTER to continue scrolling; 0 to return to menu."
        print CliController::MORE_PROMPT; input = gets.strip
      end
      if !input.nil? && input.to_i.to_s == input && input.to_i.between?(1, list_size)
        system("xdg-open", "#{category_object.audiobooks_by_title.values[input.to_i - 1].url_librivox}")
        print CliController::MORE_PROMPT; input = gets.strip
      end
      return true if input == "0"
    }
    return true
  end

end


class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end
end

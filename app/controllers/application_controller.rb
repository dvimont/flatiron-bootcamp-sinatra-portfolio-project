require './config/environment'

class ApplicationController < Sinatra::Base
  # use Rack::Flash
  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    # NOTE: not (initially) using sessions with this application, so commenting out the following
    # enable :sessions
    # set :session_secret, "sooper-dooper-secret-930022"
  end

  @@accordion_hashes = nil
  @@accordion_labels = ["AUTHOR", "READER", "LIBRIVOX GENRE", "GUTENBERG GENRE", "LANGUAGE"]
  @@accordion_classes = [Author, Reader, GenreLibrivox, GenreGutenberg, Language]

  get '/' do
    ApplicationController.setup_class_variables
    @accordion_hashes = @@accordion_hashes
    @accordion_labels = @@accordion_labels
    erb :index
  end

  post '/select' do
    puts 'selection submitted'
    redirect to '/'
  end

  def self.setup_class_variables
    return if !@@accordion_hashes.nil?

    # @@authors_hash = Author.all_by_name

    @@accordion_hashes = Array.new
    @@accordion_classes.each{ |category_subclass|
      accordion_hash = Hash.new
      ('A'..'[').to_a.each{ |letter|
        if letter == '['
          category_object_array = category_subclass.all_by_name.values_with_nonroman_key
          letter_label = "NAMES NOT IN ROMAN ALPHABET"
        else
          category_object_array = category_subclass.all_by_name.values_with_key_prefix(letter)
          letter_label = letter
        end
        if (!category_object_array.nil? && category_object_array.size > 0)
          accordion_hash[letter_label] = category_object_array
        end
      }
      @@accordion_hashes.push(accordion_hash)
    }
  end

end

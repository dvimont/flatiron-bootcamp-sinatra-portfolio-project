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

  ACCORDION_LABELS = ["AUTHOR", "READER", "LIBRIVOX GENRE", "GUTENBERG GENRE", "LANGUAGE"]
  ACCORDION_CLASSES = [Author, Reader, GenreLibrivox, GenreGutenberg, Language]
  ACCORDION_HASHES = Array.new
  DEFAULT_ERB = Array.new
  PRELOADED_ERB_ARRAY = Array.new
  ACCORDION_BYPASS_LABEL = "**BYPASS**"

  get '/' do
    self.set_preloaded_erb_array
    return DEFAULT_ERB[0]
  end

  post '/select/:selected_category_index' do
    redirect to "/category/#{params[:selected_category_index]}"
  end

  get '/category/:selected_category_index' do
    self.set_preloaded_erb_array
    return PRELOADED_ERB_ARRAY[params[:selected_category_index].to_i]
  end

  post '/audiobooks/:category_type/:object_id' do
    redirect to "/audiobooks/#{params[:category_type]}/#{params[:object_id]}"
  end

  get '/audiobooks/:category_type/:object_id' do
    category_class = ACCORDION_CLASSES.select{|klass|
      params[:category_type] == klass.to_s.downcase
    }.first
    @category_object = category_class.get(params[:object_id])
    erb :category_instance_audiobooks
  end

  def set_accordion_variables
    if ACCORDION_HASHES.empty?
      ACCORDION_CLASSES.each{ |category_subclass|
        accordion_hash = Hash.new
        if (category_subclass == GenreLibrivox || category_subclass == Language)
          category_object_array = category_subclass.all_by_name.values
          if (category_subclass == Language)
            category_object_array.delete_if { |language| language.id == "English" }
          end
          accordion_hash[ACCORDION_BYPASS_LABEL + category_subclass.to_s] = category_object_array
        else
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
        end
        ACCORDION_HASHES.push(accordion_hash)
      }
    end
  end

  def set_preloaded_erb_array()
    return if !PRELOADED_ERB_ARRAY.empty?

    self.set_accordion_variables
    DEFAULT_ERB[0] = erb :index

    (0..(ACCORDION_CLASSES.size - 1)).each{ |i|
      @selected_category_index = i
      PRELOADED_ERB_ARRAY.push(erb :index)
    }
  end
end

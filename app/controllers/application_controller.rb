require './config/environment'

class ApplicationController < Sinatra::Base
  # use Rack::Flash
  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    # NOTE: not (initially) using sessions with this application, so commenting out the following
    # enable :sessions
    # set :session_secret, "sooper-dooper-secret-930022"
    # CatalogBuilder.build
  end

  @@initialization_complete = false
  @@initialization_started = false
  ACCORDION_LABELS = ["TITLE", "AUTHOR", "READER", "LIBRIVOX GENRE", "GUTENBERG GENRE", "LANGUAGE"]
  ACCORDION_CLASSES = [Audiobook, Author, Reader, GenreLibrivox, GenreGutenberg, Language]
  ACCORDION_PNG_FILES = ["/images/title.png", "/images/author-sign.png", "/images/voice.png",
    "/images/mask.png", "/images/gutenberg.png", "/images/grid-world.png"]
  ACCORDION_HASHES = Array.new
  DEFAULT_ERB = Array.new
  PRELOADED_ERB_ARRAY = Array.new
  ACCORDION_BYPASS_LABEL = "**BYPASS**"
  SUBGROUP_SIZE = 48
  ALL_AUDIOBOOKS_ARRAY = Audiobook.all_by_title.values

  get '/' do
    self.set_preloaded_erb_array
    if !@@initialization_complete
      return erb :initializing_notice
    end
    return DEFAULT_ERB[0]
  end

  post '/select/:selected_category_index' do
    redirect to "/category/#{params[:selected_category_index]}"
  end

  get '/category/:selected_category_index' do
    self.set_preloaded_erb_array
    if !@@initialization_complete
      return erb :initializing_notice
    end
    return PRELOADED_ERB_ARRAY[params[:selected_category_index].to_i]
  end

  post '/audiobooks/new' do
    redirect to "/audiobooks/new"
  end

  get '/audiobooks/new' do
    self.set_preloaded_erb_array
    if !@@initialization_complete
      return erb :initializing_notice
    end
    @heading = "NEW Audiobooks"
    @audiobook_array = Audiobook.all_by_date.values[0..(SUBGROUP_SIZE - 1)]
    erb :category_instance_audiobooks
  end

  post '/audiobooks/title/:start_index/:end_index' do
    redirect to "/audiobooks/title/#{params[:start_index]}/#{params[:end_index]}"
  end

  get '/audiobooks/title/:start_index/:end_index' do
    self.set_preloaded_erb_array
    if !@@initialization_complete
      return erb :initializing_notice
    end
    firstTitle = Audiobook.all_by_title.values[params[:start_index].to_i].title
    lastTitle = Audiobook.all_by_title.values[params[:end_index].to_i].title
    if (firstTitle.length > 20)
      firstTitle = firstTitle[0,17] + "..."
    end
    if (lastTitle.length > 20)
      lastTitle = lastTitle[0,17] + "..."
    end
    @heading = "Audiobooks by Title: from '" +
        firstTitle +
         "'&nbsp;&nbsp;&nbsp;-- THROUGH --&nbsp;&nbsp;&nbsp;'" +
        lastTitle + "'"
    @audiobook_array =
      Audiobook.all_by_title.values[params[:start_index].to_i..params[:end_index].to_i]
    erb :category_instance_audiobooks
  end

  post '/audiobooks/:category_type/:object_id' do
    redirect to "/audiobooks/#{params[:category_type]}/#{params[:object_id]}"
  end

  get '/audiobooks/:category_type/:object_id' do
    self.set_preloaded_erb_array
    if !@@initialization_complete
      return erb :initializing_notice
    end
    category_class = ACCORDION_CLASSES.select{|klass|
      params[:category_type] == klass.to_s.downcase
    }.first
    category_object = category_class.get(params[:object_id])
    @heading = "Audiobooks for #{category_object.class.to_s.upcase} ===&gt;&gt;&gt; #{category_object.to_s}"
    @audiobook_array = category_object.audiobooks_by_title.values
    erb :category_instance_audiobooks
  end

  post '/audiobooks/random' do
    redirect to "/audiobooks/random"
  end

  get '/audiobooks/random' do
    self.set_preloaded_erb_array
    if !@@initialization_complete
      return erb :initializing_notice
    end
    @heading = "Random Browsing of the Librivox Collection!"
    @audiobook_array = Audiobook.all_by_date.values.sample(30)
    erb :category_instance_audiobooks
  end

  def set_preloaded_erb_array()
    return if !PRELOADED_ERB_ARRAY.empty?
    if !@@initialization_complete
      if !@@initialization_started
        @@initialization_started = true
        Thread.new {
            CatalogBuilder.build
            @@initialization_complete = true
        }
      end
      return
    end
    self.set_accordion_variables
    DEFAULT_ERB[0] = erb :index

    (0..(ACCORDION_CLASSES.size - 1)).each{ |i|
      @selected_category_index = i
      PRELOADED_ERB_ARRAY.push(erb :index)
    }
  end

  def set_accordion_variables
    if ACCORDION_HASHES.empty?
      ACCORDION_CLASSES.each{ |category_subclass|
        accordion_hash = Hash.new
        # No alphabetic grouping accordions for these category types
        if (category_subclass == Language)
        ## if (category_subclass == GenreLibrivox || category_subclass == Language)
          category_object_array = category_subclass.all_by_name.values
          ##if (category_subclass == Language)
            category_object_array.delete_if { |language| language.id == "English" }
          ##end
          accordion_hash[ACCORDION_BYPASS_LABEL + category_subclass.to_s] = category_object_array
        else # all other category types get alphabetic grouping and subalphabetic grouping
          ('A'..'[').to_a.each{ |letter|
            if letter == '['
              category_object_array = category_subclass.all_by_name.values_with_nonroman_key
              letter_label = "ENTRIES NOT IN ROMAN ALPHABET"
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
end

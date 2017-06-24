require './config/environment'

class ApplicationController < Sinatra::Base
  # use Rack::Flash
  CATALOG_BUILD_RESPONSE = CatalogBuilder.build(50)

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    # NOTE: not (initially) using sessions with this application, so commenting out the following
    # enable :sessions
    # set :session_secret, "sooper-dooper-secret-930022"
    if CATALOG_BUILD_RESPONSE != :successful_build
      raise RuntimeError, 'Catalog not successfully built'
    end
  end

  get '/' do
    @authors_hash = Author.all_by_name
    @readers_hash = Reader.all_by_name
    @librivox_genres_hash = GenreLibrivox.all_by_name
    @gutenberg_genres_hash = GenreGutenberg.all_by_name
    @languages_hash = Language.all_by_name
    erb :index
  end

  post '/select' do
    puts 'selection submitted'
    redirect to '/'
  end
end

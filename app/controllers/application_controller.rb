require './config/environment'

class ApplicationController < Sinatra::Base
  use Rack::Flash
  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    # NOTE: not (initially) using sessions with this application, so commenting out the following
    # enable :sessions
    # set :session_secret, "sooper-dooper-secret-930022"
  end

  get '/' do
    erb :index
  end

end

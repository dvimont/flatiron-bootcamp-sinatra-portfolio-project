require './config/environment'

warmup do |app|
  CatalogBuilder.build # (50)
end

use Rack::MethodOverride
run ApplicationController

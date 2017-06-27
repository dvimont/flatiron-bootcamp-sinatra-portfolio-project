require './config/environment'

warmup do |app|
  CatalogBuilder.build(10)
end

use Rack::MethodOverride
run ApplicationController

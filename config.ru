require './config/environment'

warmup do |app|
  CatalogBuilder.build(525)
end

# use Rack::MethodOverride
use Rack::Deflater
run ApplicationController

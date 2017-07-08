require './config/environment'

warmup do |app|
  CatalogBuilder.build # (50)
end

# use Rack::MethodOverride
use Rack::Deflater # automatically use gzip compression for all http responses
run ApplicationController

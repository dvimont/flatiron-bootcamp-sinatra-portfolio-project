require './config/environment'

# HEROKU timeouts forced move of CatalogBuilder.build invocation to ApplicationController
#warmup do |app|
#  CatalogBuilder.build(525)
#end

# use Rack::MethodOverride
use Rack::Deflater # automatically use gzip compression for all http responses
run ApplicationController

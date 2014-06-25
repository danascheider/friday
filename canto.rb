require          'sinatra'
require          'sinatra/jstpages'
require          'sinatra/assetpack'
require          'sinatra/restapi'
require          'sinatra/activerecord'
require_relative 'routes/routes'

class Canto < Sinatra::Application
  set :root, File.dirname(__FILE__)

  # The following line pertains to the database. The database
  # is not set up yet. When it is set up, this should be 
  # uncommented.
  # => set :database, {adapter: 'sqlite3', database: task.sqlite3}

  register Sinatra::AssetPack
  register Sinatra::JstPages

  # RestAPI can create RESTful resources using rest_resources and
  # rest_create methods. An example could be:
  #
  # => rest_resource '/book/:id' do |id|
  # =>   Book.find(:id => id)
  # => end
  register Sinatra::RestAPI

  serve_jst 'assets/jst.js'

  assets {
    serve '/js', from: 'assets/javascripts'
    serve '/css', from: 'assets/stylesheets'
    serve '/images', from: 'assets/images'

    js :application, '/js/application.js', ['js/application.min.js']

    css :application, 'css/application.css', ['css/application.min.css']

    js_compression :jsmin
    css_compression :simple
  }

  configure do 
    enable :sessions
  end
end

Canto.run!
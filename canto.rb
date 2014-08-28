require 'sinatra/base'
require 'sinatra/activerecord'
require 'ranked-model'
require 'json'
require 'require_all'
require File.expand_path('../config/settings', __FILE__)

require_all 'models'

class Canto < Sinatra::Base
  not_found do 
    [404, '' ]
  end

  before do
    @request_body = parse_json(request.body.read)
    @id = request.path_info.match(/\d+/).to_s
  end

  before /\/users\/(\d+)(\/*)?/ do 
    protect(User)
  end

  before /\/tasks\/(\d+)(\/*)?/ do 
    protect(Task)
  end

  before /\/admin\/*/ do 
    admin_only!
  end

  # The following paths are included for debugging purposes only:

  # get '/' do 
  #   "Hello Canto!\n"
  # end

  # post '/' do 
  #   "Hello Canto!\nYou posted #{@request_body}!\n"
  # end
  
  post '/users' do  
    validate_standard_create
    create_resource(User, @request_body)
  end

  [ '/users/:id', '/tasks/:id' ].each do |route, id|
    get route do 
      return_json(@resource) || 404
    end

    put route do 
      update_resource(@request_body, @resource)
    end

    delete route do 
      destroy_resource(@resource)
    end
  end

  post '/users/:id/tasks' do |id|
    @request_body[:task_list_id] ||= @resource.default_task_list.id
    create_resource(Task, @request_body)
  end

  get '/users/:id/tasks' do |id|
    return_json(@resource.tasks)
  end

  # Filters
  # =======

  post '/filters' do 
    protect_filter!
    filter_resources(@request_body)
  end

  # Admin-Only Routes
  # =================

  post '/admin/users' do 
    create_resource(User, @request_body)
  end

  get '/admin/users' do 
    return_json(User.all)
  end
end
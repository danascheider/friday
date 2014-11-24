require 'require_all'
require 'sinatra/base'
require 'sinatra/sequel'
require 'sequel'
require 'rack/cors'
require 'reactive_support'
require 'reactive_support/core_ext/object/blank'
require 'reactive_support/core_ext/object/inclusion'
require 'reactive_support/core_ext/object/try'
require 'reactive_support/extensions/reactive_extensions'
require 'reactive_support/extensions/array_extensions'
require 'json'
require File.expand_path('../config/settings', __FILE__)

Dir['./models/**'].each {|f| require f }
Dir['../helpers/**/*'].each {|f| require f }

class Canto < Sinatra::Base

  not_found do 
    [404, '' ]
  end

  ##### Logging #####

  before do
    @id = request.path_info.match(/\d+/).to_s
    @request_body = request_body
    log_request
  end

  after do 
    log_response
  end

  ###################

  before /^\/users\/(\d+)\/tasks/ do 
    request.put? ? protect_collection(request_body) : protect(User)
  end

  before /^\/users\/(\d+)(\/*)?/ do 
    protect(User)
  end

  before /^\/tasks\/(\d+)(\/*)?/ do 
    protect(Task)
  end

  before /\/admin\/*/ do 
    admin_only!
  end

  ##### End Filters #####

  post '/users' do  
    access_denied if setting_admin?
    return 422 unless new_user = User.try_rescue(:create, request_body)
    [201, new_user.to_json]
  end

  [ '/users/:id', '/tasks/:id' ].each do |route, id|
    get route do 
      @resource && @resource.to_json || 404
    end

    put route do 
      update_resource(request_body, @resource)
    end

    delete route do 
      return 404 unless @resource
      @resource.try_rescue(:destroy) && 204 || 403
    end
  end

  post '/users/:id/tasks' do |id|
    body = request_body
    body[:task_list_id] ||= User[id].default_task_list.id
    return 422 unless new_task = Task.try_rescue(:create, body)

    [201, new_task.to_json]
  end

  put '/users/:id/tasks' do |id|
    updated = request_body.map {|h| Task[h[:id]] } 

    request_body.each do |hash|
      updated << set_attributes(hash, (task = Task[hash[:id]]))
      return 422 unless task.valid? && task.owner_id === id.to_i
    end

    updated.each {|task| task.save } && 200 rescue 422
  end

  get '/users/:id/tasks' do |id|
    return_json(@resource.tasks.where_not(:status, 'Complete'))
  end

  get '/users/:id/tasks/all' do |id|
    return_json(@resource.tasks)
  end

  post '/login' do
    login
  end

  # Admin-Only Routes
  # =================

  post '/admin/users' do 
    request.body.rewind; @request_body = parse_json(request.body.read)
    return 422 unless new_user = User.try_rescue(:create, @request_body)
    [201, new_user.to_json]
  end

  get '/admin/users' do 
    return_json(User.all)
  end
end
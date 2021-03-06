# View Task List
# ==============
When(/^the client submits a GET request to \/users\/(\d+)\/tasks with the (\d+)(?:[a-z]{2}) user's credentials$/) do |id1, id2|
  @user, @current = User[id1], User[id2]
  authorize_with @current 
  get "/users/#{id1}/tasks"
end

When(/^the client submits a GET request to \/users\/(\d+)\/tasks\/all with the (\d+)(?:[a-z]{2}) user's credentials$/) do |id1, id2|
  @user, @current = User[id1], User[id2]
  authorize_with @current 
  get "/users/#{id1}/tasks/all"
end

# View Task(s)
# ============
When(/^the client submits a GET request to \/tasks\/(\d+) with the (\d+)(?:[a-z]{2}) user's credentials$/) do |task_id, user_id|
  @task, @current = Task[task_id], User[user_id]
  authorize_with @current
  get "/tasks/#{task_id}"
end

# View User Profile
# =================
When(/^the client submits a GET request to \/users\/(\d+) with the (\d+)(?:[a-z]{2}) user's credentials$/) do |req_id, actual_id|
  @user, @current = User[req_id], User[actual_id]
  authorize_with @current
  get "/users/#{req_id}"
end

# View All Users
# ==============
When(/^the client submits a GET request to \/admin\/users with the (\d+)(?:[a-z]{2}) user's credentials$/) do |id|
  @current = User[id]
  authorize_with @current
  get '/admin/users'
end

# View Organization
# =================

When(/^the client submits a GET request to its individual endpoint with (.*) credentials$/) do |type|
  authorize_with User[type === 'admin' ? 1 : 2] unless type === 'no'
  get "/organizations/#{@organization.id}"
end

When(/^the client submits a GET request to \/(organizations|churches)\/(\d+) with (user|admin) credentials$/) do |path, id, type|
  @organization = path.match(/church/) ? Church[id] : Organization[id]
  authorize_with User[type === 'admin' ? 1 : 2]
  get "/#{path}/#{id}"
end

# View All Organizations
# ======================

When(/^the client submits a GET request to \/(organizations|churches) with user credentials$/) do |path|
  authorize_with User[2]
  get "/#{path}"
end

# View Program
# ============

When(/^the client submits a GET request to \/programs\/(\d+) with (admin|user) credentials$/) do |id, type|
  @program = Program[id]
  authorize_with User[type === 'admin' ? 1 : 2]
  get "/programs/#{id}"
end

# View Collection of Programs
# ===========================

When(/^the client submits a GET request to \/organizations\/(\d+)\/programs with (admin|user) credentials$/) do |id, type|
  @organization = Organization[id]
  authorize_with User[type === 'admin' ? 1 : 2]
  get "/organizations/#{id}/programs"
end

When(/^the client submits a GET request to \/organizations\/(\d+)\/programs with invalid credentials$/) do |id|
  @organization = Organization[id]
  authorize 'baduser', 'malicious666'
  get "/organizations/#{id}/programs"
end

When(/^the client submits a GET request to \/programs with (admin|user) credentials$/) do |type|
  authorize_with User[type === 'admin' ? 1 : 2]
  get '/programs'
end

When(/^the client submits a GET request to \/programs with invalid credentials$/) do
  authorize 'baduser', 'malicious666'
  get '/programs'
end

# View Single Season 
# ==================
When(/^the client submits a GET request to \/seasons\/(\d+) with (.*) authorization$/) do |id, type|
  authorize_with User[type === 'admin' ? 1 : 2] unless type === 'no'
  get "/seasons/#{id}"
end

# View Multiple Seasons of One Program
# ====================================
When(/^the client submits a GET request to \/programs\/(\d+)\/seasons with (.*) authorization$/) do |id, type|
  @program = Program[id]
  authorize_with User[type === 'admin' ? 1 : 2] unless type === 'no'
  get "/programs/#{id}/seasons"
end

When(/^the client submits a GET request to \/programs\/(\d+)\/seasons\/all with (.*) authorization$/) do |id, type|
  @program = Program[id]
  authorize_with User[type === 'admin' ? 1 : 2] unless type === 'no'
  get "/programs/#{id}/seasons/all"
end

# Unauthorized
# ============
When(/^the client submits a GET request to (.*) with no credentials$/) do |path|
  get path
end

When(/^the client submits a GET request to \/users with the (\d+)(?:[a-z]{2}) user's credentials$/) do |id|
  @current = User[id]
  authorize_with @current
  get '/users'
end
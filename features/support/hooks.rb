Before do
  User.dataset = User.dataset
  FactoryGirl.create(:admin, id: 1, email: 'admin@example.com', username: 'abcd1234', password: 'abcde12345')
  FactoryGirl.create(:user, id: 2, email: 'user2@example.com', username: 'bcde2345', password: 'bcdef23456')
  FactoryGirl.create(:user, id: 3, email: 'user3@example.com', username: 'cdef3456', password: 'cdefg34567')
  @user_count = User.count
end

# This seems like a smell, but the fact is that sometimes I just need
# to know exactly what the tasks' IDs are.
Before('@tasks') do |scenario|
  list_id_1 = User[1].default_task_list.id
  list_id_2 = User[2].default_task_list.id
  list_id_3 = User[3].default_task_list.id

  FactoryGirl.create(:task, task_list_id: list_id_1, id: 1)
  FactoryGirl.create(:task, task_list_id: list_id_1, id: 2)
  FactoryGirl.create(:task, task_list_id: list_id_1, id: 3)

  FactoryGirl.create(:task, task_list_id: list_id_2, id: 4)
  FactoryGirl.create(:task, task_list_id: list_id_2, id: 5)
  FactoryGirl.create(:task, task_list_id: list_id_2, id: 6)

  FactoryGirl.create(:task, task_list_id: list_id_3, position: 10, id: 7)
  FactoryGirl.create(:task, task_list_id: list_id_3, position: 9, id: 8)
  FactoryGirl.create(:task, task_list_id: list_id_3, position: 8, id: 9)
end

# Testing task positioning requires a user to have more tasks
Before('@position') do
  list_id = User[3].default_task_list.id
  FactoryGirl.create(:task, task_list_id: list_id, position: 7, id: 10)
  FactoryGirl.create(:task, task_list_id: list_id, position: 6, id: 11)
  FactoryGirl.create(:task, task_list_id: list_id, position: 5, id: 12)
  FactoryGirl.create(:task, task_list_id: list_id, position: 4, id: 13)
  FactoryGirl.create(:task, task_list_id: list_id, position: 3, id: 14)
  FactoryGirl.create(:task, task_list_id: list_id, position: 2, id: 15)
  FactoryGirl.create(:task, task_list_id: list_id, position: 1, id: 16)
end

Before('@organizations, @programs') do 
  FactoryGirl.create(:organization, id: 1)
end

Before('@programs') do 
  FactoryGirl.create(:program, id: 1, organization: Organization[1])
end

# Expects Canto front-end to be running on webserver listening on port 80
Before('@integration') do 
  Capybara.app_host = 'http://localhost:80'
  Capybara.run_server = false
end
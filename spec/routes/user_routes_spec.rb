require 'spec_helper'

describe Canto, users: true do 
  include Sinatra::ErrorHandling

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:model) { User }

  describe 'POST' do 
    let(:path) { '/users' }
    let(:valid_attributes) { 
                             { :email      => 'user@example.com', 
                               :username   => 'justine7', 
                               :first_name => 'Justine',
                               :last_name  => 'Kellner',
                               :password   => 'validpassword666'
                             } 
                           }
    let(:invalid_attributes) { { :first_name => 'Frank' } }

    context 'with valid attributes' do 
      it 'calls the User create method' do 
        expect(User).to receive(:try_rescue).with(:create, valid_attributes)
        post path, valid_attributes.to_json, 'CONTENT-TYPE' => 'application/json'
      end

      it 'returns status 201' do 
        post path, valid_attributes.to_json, 'CONTENT-TYPE' => 'application/json'
        expect(last_response.status).to eql 201
      end
    end

    context 'with invalid attributes' do 
      it 'attempts to create a user' do 
        expect(User).to receive(:create)
        post '/users', invalid_attributes.to_json, 'CONTENT-TYPE' => 'application/json'
      end

      it 'returns status 422' do 
        post '/users', invalid_attributes.to_json, 'CONTENT-TYPE' => 'application/json'
        expect(last_response.status).to eql 422
      end
    end

    context 'attempting to create an admin' do
      let(:admin_attributes) { 
        { 
          :username   => 'someuser', 
          :password   => 'someuserpasswd', 
          :email      => 'peterpiper@example.com',
          :first_name => 'Peter',
          :last_name  => 'Piper',
          :admin      => true
         }
      }

      context 'to the main /users path' do 
        it 'doesn\'t create the user' do 
          expect(User).not_to receive(:create)
          post '/users', admin_attributes.to_json, 'CONTENT-TYPE' => 'application/json'
        end

        it 'returns status 401' do 
          post '/users', admin_attributes.to_json, 'CONTENT-TYPE' => 'application/json'
          expect(last_response.status).to eql 401
        end
      end

      context 'without providing admin credentials' do 
        it_behaves_like 'an unauthorized POST request' do 
          let(:path) { '/admin/users' }
          let(:agent) { user }
          let(:valid_attributes) { admin_attributes.to_json }
        end
      end

      context 'with proper admin credentials' do
        it_behaves_like 'an authorized POST request' do 
          let(:path) { '/admin/users' }
          let(:agent) { admin }
          let(:valid_attributes) { admin_attributes.to_json }
        end
      end
    end
  end

  describe 'GET' do 
    let(:resource) { user }
    let(:path) { "/users/#{resource.id}" }

    context 'with user\'s credentials' do 
      it_behaves_like 'an authorized GET request' do 
        let(:agent) { user }
      end
    end

    context 'with admin credentials' do 
      it_behaves_like 'an authorized GET request' do 
        let(:agent) { admin }
      end
    end

    context 'with the wrong password' do 
      it_behaves_like 'an unauthorized GET request' do 
        let(:username) { user.username }
        let(:password) { 'foobar' }
      end
    end

    context 'with invalid credentials' do 
      it_behaves_like 'an unauthorized GET request' do 
        let(:resource) { admin.to_json }
        let(:username) { user.username }
        let(:password) { user.password }
        let(:path) { "/users/#{admin.id}" }
      end
    end

    context 'with no credentials' do 
      it_behaves_like 'a GET request without credentials' do 
        let(:resource) { user.to_json }
        let(:path) { "/users/#{user.id}" }
      end
    end

    context 'when the user doesn\'t exist' do 
      it 'returns status 404' do 
        authorize_with admin
        get '/users/1000000'
        expect(last_response.status).to eql 404
      end
    end
  end

  describe 'PUT' do 
    let(:path) { "/users/#{user.id}" }
    let(:valid_attributes) { { :fach => 'lyric spinto' }.to_json }
    let(:invalid_attributes) { { :username => nil }.to_json }
    let(:resource) { user } 

    context 'with user authorization' do 
      it_behaves_like 'an authorized PUT request' do 
        let(:agent) { user }
      end

      context 'attempting to set admin status to true' do 
        before(:each) do 
          authorize_with user 
        end

        it 'doesn\'t update the profile' do 
          expect_any_instance_of(User).not_to receive(:update)
          put "/users/#{user.id}", { :admin => true }.to_json, 'CONTENT-TYPE' => 'application/json'
        end

        it 'returns status 401' do 
          put "/users/#{user.id}", { :admin => true }.to_json, 'CONTENT-TYPE' => 'application/json'
          expect(last_response.status).to eql 401
        end
      end
    end

    context 'with admin authorization' do 
      it_behaves_like 'an authorized PUT request' do 
        let(:agent) { admin }
      end
    end

    context 'with invalid authorization' do 
      it_behaves_like 'an unauthorized PUT request' do 
        let(:agent) { user }
        let(:path) { "/users/#{admin.id}" }
      end
    end

    context 'with no authorization' do 
      it_behaves_like 'a PUT request without credentials'
    end

    context 'when the user doesn\'t exist' do 
      it 'returns status 404' do 
        authorize_with admin
        put '/users/1000000', { :fach => 'lyric coloratura' }.to_json, 'CONTENT-TYPE' => 'application/json'
        expect(last_response.status).to eql 404
      end
    end
  end

  describe 'DELETE' do 
    let(:path) { "/users/#{user.id}" }

    context 'with user credentials' do 
      it_behaves_like 'an authorized DELETE request' do 
        let(:agent) { user }
        let(:nonexistent_resource_path) { '/users/1000000'}
      end
    end

    context 'with admin credentials' do 
      it_behaves_like 'an authorized DELETE request' do 
        let(:agent) { admin }
        let(:nonexistent_resource_path) { '/users/1000000' }
      end
    end

    context 'with invalid credentials' do 
      it_behaves_like 'an unauthorized DELETE request' do 
        let(:path) { "/users/#{admin.id}" }
        let(:agent) { user }
      end
    end

    context 'with no credentials' do 
      it_behaves_like 'a DELETE request without credentials' 
    end
  end
end
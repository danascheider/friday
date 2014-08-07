shared_examples 'an authorized PUT request' do 
  context 'with valid attributes' do 
    it 'updates the resource' do 
      expect_any_instance_of(model).to receive(:update!).with(JSON.parse(valid_attributes))
      authorize_with agent
      make_request('PUT', path, valid_attributes)
    end

    it 'returns status 200' do 
      authorize_with agent
      make_request('PUT', path, valid_attributes)
      expect(response_status).to eql 200
    end
  end

  context 'with invalid attributes' do 
    it 'returns status 422' do 
      authorize_with agent
      make_request('PUT', path, invalid_attributes)
    end
  end
end

shared_examples 'an unauthorized PUT request' do 
  it 'doesn\'t update the resource' do 
    expect_any_instance_of(model).not_to receive(:update).with(JSON.parse(valid_attributes))
    authorize_with agent 
    make_request('PUT', path, valid_attributes)
  end

  it 'returns status 401' do 
    authorize_with agent
    make_request('PUT', path, valid_attributes)
    expect(response_status).to eql 401
  end
end

shared_examples 'a PUT request without credentials' do 
  it 'doesn\'t update the resource' do 
    expect_any_instance_of(model).not_to receive(:update!).with(valid_attributes)
    make_request('PUT', path, valid_attributes)
  end

  it 'returns status 401' do 
    make_request('PUT', path, valid_attributes)
    expect(response_status).to eql 401
  end
end
Then(/^the (\d+)(?:[a-z]{2}) task's index should be changed to (\d+)$/) do |id, index_val|
  find_task(id).index.should eql index_val.to_i
end
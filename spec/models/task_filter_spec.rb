require 'spec_helper'

describe TaskFilter do 
  let(:task_list) { FactoryGirl.create(:task_list_with_complete_and_incomplete_tasks) }

  before(:each) do 
    @list, i = task_list, 1
    @list.tasks.each {|task, n| task.update!(deadline: Time.utc(2014, 9, i)); i+= 1 }
    @task = Task.where(deadline: Time.utc(2014,9,3)).first
    @task.update!(priority: 'high')
  end

  describe '#filter' do 
    context 'with simple categorical conditions' do 
      let(:conditions) { { priority: 'high' } }
      let(:filter) { TaskFilter.new(conditions, @list.owner_id) }

      it 'returns an ActiveRecord::Relation' do 
        expect(filter.filter).to be_an(ActiveRecord::Relation)
      end

      it 'returns the high-priority task' do 
        expect(filter.filter.to_a).to eql [@task]
      end
    end

    context 'with simple time conditions' do 
      let(:conditions) { { deadline: { on: { year: 2014, month: 9, day: 3 }}}}
      let(:filter) { TaskFilter.new(conditions, @list.owner_id) }

      it 'returns an ActiveRecord::Relation' do 
        expect(filter.filter).to be_an(ActiveRecord::Relation)
      end

      it 'returns the task with the given deadline' do 
        expect(filter.filter.to_a).to eql [@task]
      end
    end

    context 'with one-sided :before interval' do 
      let(:conditions) { { deadline: { before: { year: 2014, month: 9, day: 3 } } } }
      let(:filter) { TaskFilter.new(conditions, @list.owner_id) }

      it 'returns an ActiveRecord::Relation' do 
        expect(filter.filter).to be_an(ActiveRecord::Relation)
      end

      it 'returns the tasks with earlier deadlines' do 
        expect(filter.filter.to_a).to eql Task.where('deadline < ?', Time.utc(2014,9,3)).to_a
      end

      # it 'excludes the tasks with equal or later deadlines' do 
      #   expect(filter.filter.to_a && Task.where('deadline > ?', Time.utc(2014,9,2).to_a)).to eql []
      # end
    end
  end
end
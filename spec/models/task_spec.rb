require 'spec_helper'

describe Task do 
  let(:task) { FactoryGirl.create(:task) }

  describe 'attributes' do 
    it { is_expected.to respond_to(:title) }
    it { is_expected.to respond_to(:status) }
    it { is_expected.to respond_to(:position) }
    it { is_expected.to respond_to(:deadline) }
    it { is_expected.to respond_to(:description) }
    it { is_expected.to respond_to(:priority) }
    it { is_expected.to respond_to(:owner_id) }
  end

  describe 'public instance methods' do 
    it { is_expected.to respond_to(:complete?) }
    it { is_expected.to respond_to(:incomplete?) }
    it { is_expected.to respond_to(:to_hash) }
    it { is_expected.to respond_to(:user) }
    it { is_expected.to respond_to(:owner) }
    it { is_expected.to respond_to(:siblings) }
  end

  describe 'public methods' do 
    before(:each) do 
      @task_list     = FactoryGirl.create(:task_list_with_complete_and_incomplete_tasks)
      @complete_task = Task.where(task_list_id: @task_list.id, status: 'complete').first
    end

    describe '::first_complete' do 
      it 'returns the  first complete task' do 
        expect(Task.first_complete).to eql @complete_task.to_hash
      end
    end

    describe '#complete?' do 
      it 'returns true when a task is complete' do 
        expect(@complete_task.complete?).to be_truthy
      end

      it 'returns false when a task is incomplete' do 
        expect(task.complete?).to be_falsey
      end
    end

    describe '#incomplete?' do 
      it 'returns true when a task is incomplete' do 
        expect(task.incomplete?).to be_truthy
      end

      it 'returns false when a task is complete' do 
        expect(@complete_task.incomplete?).to be_falsey
      end
    end

    describe '#siblings' do 
      before(:each) do 
        @task = @task_list.tasks.first
      end

      it 'returns an array' do 
        expect(@task.siblings).to be_an(Array)
      end

      it 'doesn\'t include the task calling the method' do 
        expect(@task.siblings).not_to include(@task)
      end

      it 'includes the task\'s siblings' do 
        expect(@task.siblings).to eql(@task_list.tasks.to_a - [@task])
      end
    end

    describe '#user' do 
      it 'returns the user who owns the task list containing the task' do 
        expect(task.user).to eql task.task_list.user
      end
    end

    describe '#owner' do 
      it 'returns a user model' do 
        expect(task.owner).to be_a(User)
      end

      it 'is equivalent to #user' do 
        expect(task.owner).to eql task.user
      end
    end
  end

  describe 'validations' do 
    before(:each) do 
      @task = FactoryGirl.build(:task, title: 'Foo', status: 'new', priority: 'high')
    end

    context 'when valid' do 
      it 'should be valid' do 
        expect(@task).to be_valid
      end
    end

    context 'pertaining to title' do 
      it 'is invalid without a title' do 
        @task.title = nil
        expect(@task).not_to be_valid
      end
    end

    context 'pertaining to status' do 
      it 'doesn\'t permit invalid status' do 
        @task.status = "Bar"
        expect(@task).not_to be_valid
      end
    end

    context 'pertaining to priority' do 
      it 'doesn\'t permit invalid priorities' do 
        @task.priority = 'Bar'
        expect(@task).not_to be_valid
      end
    end

    context 'pertaining to associations' do 
      it 'can\'t be saved without a task list' do 
        @task.task_list_id = nil 
        expect(@task).not_to be_valid
      end
    end
  end

  describe 'default behavior' do 
    let(:list) { FactoryGirl.create(:task_list_with_tasks, tasks_count: 5) }
    let(:new_task) { FactoryGirl.create(:task, task_list_id: list.id, title: 'New Task') }

    it 'sets status to \'new\'' do
      expect(new_task.status).to eql 'new'
    end

    it 'sets priority to \'normal\'' do 
      expect(new_task.priority).to eql 'normal'
    end

    it 'assigns an owner id' do 
      expect(new_task.owner_id).to eql list.user.id
    end

    context 'when status is set to complete' do 
      it 'instantiates as the first complete task' do 
        expect(FactoryGirl.create(:task, title: 'Foo', status: 'complete', task_list_id: list.id).position).to eql 5
      end
    end

    context 'when status is not set to complete' do 
      it 'instantiates at position 0' do 
        expect(new_task.position).to eql 0
      end
    end
  end

  describe 'associations' do 
    let(:list) { FactoryGirl.create(:task_list_with_tasks) }

    it 'is destroyed with its parent list' do 
      @task = list.tasks.first
      list.destroy
      expect(get_resource(Task, @task.id)).to eql nil
    end
  end
end
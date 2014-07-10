class Sinatra::Application

  module TaskController

    # The begin_and_rescue method is defined in the ErrorHandling module.

    # BASIC CONTROLLER METHODS
    # ========================

    def create_task(body)
      body[:index] = body[:index] ? validate_index(body[:index], :create) : assign_default_index(body)
      Task.create!(body) && TaskIndexer.update_indices
    end

    def get_task(id)
      find_task(id).to_json
    end

    def update_task(id, body)
      @task = find_task(id)
      body[:index] = body[:index] ? validate_index(body[:index]) : nil
      body[:index] ||= index_on_completion_status(@task, body)
      @task.update!(body) && TaskIndexer.update_indices
    end

    def delete_task(id)
      Task.find(id).destroy 
      TaskIndexer.update_indices(Task.pluck(:index).sort)
    end

    # HELPER METHODS
    # ==============
    def index_on_completion_status(task, object)
      if (object.has_key? :complete) && (object[:complete] != task.complete)
        object[:complete] == true ? Task.count : 1
      end
    end

    # FIX: Should be deleted and tested if app works without this
    # def changed_index?(task, object)
    #   object[:index] && object[:index] != task.index
    # end
    
    protected
      def assign_default_index(object)
        object[:complete] ? Task.complete.pluck(:index).sort[0] : 1
      end

      def validate_index(index, method=:update)
        max = method == :create ? (Task.max_index + 1) : Task.max_index
        if index < 1 then 1; elsif index > max then max; else index; end
      end
  end

  helpers TaskController
end
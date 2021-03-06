# The Task model is owned by the TaskList (although this is likely to change
# in the near future). It has the following attributes:
#   * id (primary key, integer)
#   * task_list_id (foreign key, integer)
#   * title (string)
#   * status (string)
#   * priority (string)
#   * deadline (datetime)
#   * description (text)
#   * owner_id (integer)
#   * created_at (timestamp)
#   * updated_at (timestamp)
#   * backlog (boolean)
#   * position (integer)

class Task < Sequel::Model
  many_to_one :task_list

  # The ++dirty++ plugin makes old attribute values available to hooks

  self.plugin :dirty

  # Possible values for task status and priority, enforced on validation

  STATUS_OPTIONS   = [ 'New', 'In Progress', 'Blocking', 'Complete' ]
  PRIORITY_OPTIONS = [ 'Urgent', 'High', 'Normal', 'Low', 'Not Important' ]

  # By default, tasks are created at the top of the list. If the is being created
  # with status 'Complete', then it is added by default as the first complete task
  # unless a different position is specified explicitly.
  
  def before_create
    self.position = set_position
    super 
  end

  # By default, tasks that are marked as backlogged are moved below other incomplete tasks;
  # tasks marked complete are moved to the bottom of the list. When a task is marked as 
  # backlogged, it is automatically moved to the position just below that of the last 
  # "fresh" (i.e. incomplete and non-backlogged) task. When a task is marked complete -
  # whether fresh or backlogged - the task is moved to the position just below that of
  # the last incomplete, backlogged task (or the last incomplete task, if there are no
  # backlogged tasks).

  def before_update
    return unless needs_positioning? 
    scope = marked_complete? ? :incomplete : :fresh
    self.position = Task.highest_position(self.owner_id, scope) unless fresh?
    self.position += 1 if self.backlog && marked_incomplete?
    self.position = 1 if fresh?
    super
  end

  # When a task has been saved, either on create or on update, the ++after_save++
  # hook adjusts the positions of the other tasks belonging to the same user 
  # such that there are no gaps or duplicate indices on the list

  def after_save
    super
    Task.adjust_positions(self)
  end

  # When a task is destroyed, the rest of the tasks with the same owner should
  # have their list position incremented such that there are no gaps in the 
  # indices. 

  def after_destroy
    super
    Task.where('position > ?', position).each {|t| t.this.update(position: t.position - 1 )}
  end

  # The ++before_validation++ hook assigns automatic values before a task is 
  # validated on creation or update:
  # * Ensures that a task list has been specified
  # * Assigns the ++:owner_id++ attribute based on the owner of the specified task list
  # * Sets ++:status++ to a default value of 'New' unless a valid status is given
  # * Sets ++:priority++ to a default value of 'Normal' unless a valid priority level
  #   is given

  def before_validation
    super
    self.owner_id ||= task_list.user_id rescue false
    self.status   = 'New' unless status.in? STATUS_OPTIONS
    self.priority = 'Normal' unless priority.in? PRIORITY_OPTIONS
    self.backlog = nil if self.status === 'Complete'
  end

  # The ++Task.complete++ scope returns all tasks whose status is 'Complete'

  def self.complete
    Task.where(status: 'Complete')
  end

  # The ++Task.fresh++ scope includes all tasks that are neither complete
  # nor backlogged

  def self.fresh
    Task.exclude(status: 'Complete').exclude(backlog: true)
  end

  # The ++Task.incomplete++ scope includes all tasks with a status other 
  # than 'Complete'. 

  def self.incomplete
    Task.exclude(status: 'Complete')
  end

  # The ++::highest_position++ method finds the highest position in the list
  # of tasks belonging to a given user, identified by ++owner_id++, and 
  # satisfying an optional ++scope++. It returns the highest position as an
  # integer.

  def self.highest_position(owner_id, scope=:all)
    Task.send(scope).where(owner_id: owner_id).map(&:position).max
  end

  # The ++Task.stale++ scope includes all tasks that are either complete or
  # backlogged.

  def self.stale
    Task.where('status=? or backlog=?', 'Complete', true)
  end

  # The ++#complete?++ method returns true if the task's status attribute is 
  # set to 'Complete' and false otherwise.

  def complete?
    !incomplete?
  end

  # The ++#fresh?++ method returns true if the task is not backlogged and its
  # status is anything other than 'Complete'. If a task is backlogged or 
  # complete, ++#fresh?++ returns false.

  def fresh?
    incomplete? && !backlog
  end

  # The ++#incomplete?++ method returns true if the task's status has any value
  # other than 'Complete'. If the task is complete, it returns false.

  def incomplete?
    status != 'Complete'
  end

  # The ++#to_hash++ or ++#to_h++ method returns a hash of all of the task's 
  # non-empty attributes. Keys for blank attributes are removed from the
  # hash, so not all columns will necessarily be represented in the hash.

  def to_hash
    super.reject {|k,v| v.blank? }
  end

  alias_method :to_h, :to_hash

  # Overwrites the default ++#to_json++ method to return a JSON object based
  # on the task's attribute hash
  #
  # NOTE: The definition of ++#to_json++ has to include the optional ++opts++
  #       arg, because in some of the tests, a JSON::Ext::Generator::State
  #       object is passed to the method. I am not sure why this happens,
  #       but including the optional arg makes it work as expected.

  def to_json(opts={})
    to_h.to_json
  end

  # The ++user++ method returns the user who ultimately owns the task. Since
  # users own tasks only through the ++:task_lists++ table, this provides
  # a direct reference to the user object that owns the list the given
  # task is on.

  def user
    task_list.user
  end
  alias_method :owner, :user

  # The ++validate++ method verifies that the task has a ++:name++
  # and that its ++:status++ and ++:priority++ are drawn from the set of 
  # allowed values for those attributes, returning a ++Sequel::ValidationError++ 
  # if these conditions are not met. It also calls the ++validate++ method 
  # inherited from the ++Sequel::Model++ instance, which is made available by 
  # the ++:validation_helpers++ plugin.

  def validate
    super
    validates_presence [:title, :task_list_id, :owner_id]
    validates_includes STATUS_OPTIONS, :status
    validates_includes PRIORITY_OPTIONS, :priority
  end

  private

    # The Task.update_positions method uses ++task.this++ to carry out the 
    # #update action on a dataset consisting of the task. This is done to 
    # skip the ++before_update++/++before_save++ hook calling update_positions,
    # which would lead to infinite recursion.

    def self.adjust_positions(changed)
      positions = (scoped_tasks = Task.where(owner_id: changed.owner_id)).map(&:position).sort!

      values = Task.return_values(positions)

      return true if values === []

      # Tasks iterate through tasks, updating the positions. Note the use
      # of ++t.this.update(args)++ - this carries out the ++update++ action on
      # a Sequel::Dataset representation of the task model, thus bypassing
      # any hooks otherwise triggered by an update.

      scoped_tasks.where([[:position, values[0]..values[1]]]).each do |t|
        t.this.update(position: t.position + values[2]) unless t === changed
      end
    end

    def self.return_values(positions) 
      dup, gap = Task.get_dup_and_gap(positions)[0], Task.get_dup_and_gap(positions)[1]

      # No ++dup++ and no ++gap++ indicates no positions have been changed.
      # (A ++gap++ with no ++dup++ indicates a task was destroyed, in which case
      # that will be taken care of in the ++after_destroy++ hook.)

      return [] unless dup

      # This method returns an array with three elements: A minimum
      # value, a maximum value, and an incrementor. The three arrangements
      # of this array reflect three possible situations:
      #   1. A task has been moved towards the top of the list (its 
      #      position number has gotten lower)
      #   2. A task has been moved towards the bottom of the list
      #      (its position number has gotten higher)
      #   3. A task has been added to the list

      return [dup, positions.count, 1] unless gap
      return [dup, gap].sort << (gap < dup ? -1 : 1)
    end

    # The ++Task.get_dup_and_gap++ method takes a sorted list of indices as 
    # a parameter and returns the value of any duplicates, as well as any
    # indices that are missing between the lowest and highest indices on 
    # the list.

    def self.get_dup_and_gap(positions)

      # When a new task has been added or the position of a task has been
      # changed, one or both of two things will happen to the sequence of 
      # positions:
      #   1. A duplicate position will appear at the position the 
      #      task was created at or moved to
      #   2. A gap will appear at the position the task was removed from
      #
      # ++dup++ and ++gap++ represent the duplicate position number and the 
      # missing position number, respectively
      
      dup = positions.find {|number| positions.count(number) > 1 }
      gap = (1..positions.last).find {|number| positions.count(number) === 0 }
      [dup, gap]
    end

    def added_to_backlog?
      modified?(:backlog) && backlog === true
    end

    def completion_status_changed?
      marked_complete? || marked_incomplete?
    end

    def marked_complete?
      modified?(:status) && initial_value(:status) != 'Complete' && status === 'Complete'
    end

    def marked_incomplete?
      modified?(:status) && initial_value(:status) === 'Complete' && status != 'Complete'
    end

    def needs_positioning?
      (completion_status_changed? || column_changed?(:backlog)) && !modified?(:position)
    end

    def removed_from_backlog?
      modified?(:backlog) && !backlog
    end

    def set_position

      # If the task's position has been explicitly set, then the given position 
      # should be honored.

      return self.position unless self.position.nil?

      # By default, tasks are sorted by the following order:
      #   1. Fresh tasks
      #   2. Backlogged tasks
      #   3. Complete tasks
      #
      # Because a user may override the defaults, the "zone" for each type of task is 
      # considered to be below the last task (by position) in the given category. 

      backlog_position = (Task.fresh.map(&:position).try_rescue(:max) || 0) + 1 
      complete_position = (Task.incomplete.map(&:position).try_rescue(:max) || 0) + 1

      position = self.fresh? ? 1 : (self.incomplete? ? backlog_position : complete_position)
      position
    end
end
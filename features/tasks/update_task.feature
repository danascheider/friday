@tasks
Feature: Update task

  In order to keep the most current information about my tasks & schedule
  I need to edit my tasks

  Scenario Outline: Authorized user updates task with valid attributes
    When the client submits a PUT request to /tasks/<task_id> with <type> credentials and:
      """json
      { "<attribute>":"<value>" }
      """
    Then the task's <attribute> should be changed to <value>
    And the response should indicate the task was updated successfully

    Examples:
      | task_id | type           | attribute | value              |
      | 9       | the 3rd user's | title     | Take out the trash |
      | 9       | the 1st user's | title     | Feed the cat       |

  Scenario Outline: Unauthorized user attempts to update task
    When the client submits a PUT request to /tasks/3 with <type> credentials and:
      """json
      { "<attribute>":"<value>" }
      """
    Then the task's <attribute> should not be changed to <value>
    And the response should indicate the request was unauthorized

    Examples:
      | type           | attribute | value                 | 
      | the 3rd user's | title     | Feed the cat          |
      | no             | title     | Rescue Princess Peach |

  Scenario: User attempts to update a task that doesn't exist
    When the client submits a PUT request to /tasks/1000000 with the 1st user's credentials and:
      """json
      { "status":"Complete" }
      """
    Then the response should indicate the task was not found

  Scenario: Attempt to update task with invalid attributes
    When the client submits a PUT request to /tasks/1 with the 1st user's credentials and:
      """json
      { "title":null }
      """
    Then the task's title should not be changed
    And the response should indicate the task was not updated successfully

  Scenario: Change backlogged task status to 'Complete'

    Complete tasks can not be backlogged. If a task is backlogged and then marked complete,
    it should have its backlog status automatically changed to false.

    Given the 1st task is incomplete
    And the 1st task is backlogged
    When the client submits a PUT request to /tasks/1 with the 1st user's credentials and:
      """json
      { "status":"Complete" }
      """
    Then the 1st task should not be backlogged

  Scenario Outline: Authorized mass update
    When the client submits a PUT request to /users/2/tasks with the <id> user's credentials and:
      """json
      [{ "id":4, "position":1 }, { "id":5, "position":2 }, { "id":6, "position":3 }]
      """
    Then the tasks' positions should be changed 
    And the response should indicate the tasks were saved successfully

    Examples:
      | id  |
      | 1st | 
      | 2nd |

  Scenario: Task not found
    When the client submits a PUT request to /users/2/tasks with the 2nd user's credentials and:
      """json
      [{ "id":1, "title":"Hello" }, { "id":2, "title":"world" }, { "id":471, "position":3 }]
      """
    Then the existent tasks should not be updated
    And the response should indicate the request was unauthorized

  Scenario: Unauthorized mass update
    When the client submits a PUT request to /users/2/tasks with the 3rd user's credentials and:
      """json
      [{ "id":3, "position":1 }, { "id":4, "position":2 }, { "id":5, "position":3 }]
      """
    Then the tasks' positions should not be changed
    And the response should indicate the request was unauthorized
    
    # It was going to be a challenge to change the app to return a 404 or 422 error
    # here instead of a 401, and it was frankly not important enough to me.

  Scenario Outline: Request includes task belonging to different user
    When the client submits a PUT request to /users/2/tasks with the <id> user's credentials and:
      """json
      [{ "id":3, "position":1 }, { "id":4, "position":2 }, { "id":7, "position":3 }]
      """
    Then the tasks' positions should not be changed
    And the response should indicate the <outcome>

    Examples:
      | id  | outcome                           |
      | 1st | tasks were not saved successfully |
      | 3rd | request was unauthorized          |
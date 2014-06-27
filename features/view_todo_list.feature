Feature: View to-do list 
  In order to see an overview of all the things I need to do
  As a user
  I need to see my to-do list

  Scenario: To-do list is empty
    Given there are no tasks
    When I go to the to-do list
    Then I should not see any tasks
    And I should see a message stating I have no tasks
    And I should see a link to create a new task

  Scenario: There are tasks on the to-do list
    Given there are 3 tasks
    And the tasks are incomplete
    When I go to the to-do list
    Then I should see a list of all the tasks
    And their details should be hidden

  Scenario: One of the tasks is completed
    Given there are 3 tasks
    And one of the tasks is complete
    When I go to the to-do list
    Then I should not see the completed task on the list
@users
Feature: Admin users

  Scenario Outline: Creating an admin user
    When the client submits a POST request to <url> with <type> credentials and:
      """json
      { "username":"def456", "password":"defgh45678", "email":"user4@example.com", "admin":"true" }
      """
    Then <article> new user should be created with the following attributes:
      | username | password   | email             | admin |
      | def456   | defgh45678 | user4@example.com | true  |
    And the response should return status <status>

    Examples:
    | url          | type   | article | status |
    | /users       | user   |    no   |  401   |
    | /admin/users | admin  |    a    |  201   | 
    | /admin/users | user   |    no   |  401   |
    | /admin/users | no     |    no   |  401   |

  Scenario Outline: Making a user an admin
    When the client submits a PUT request to /users/3 with <type> credentials and:
      """json
      { "admin":"true" }
      """
    Then the 3rd user should <negation> be an admin
    And the response should return status <status>

    Examples:
      | type  | negation | status |
      | admin |   yes    | 200    |
      | user  |   not    | 401    |
      | no    |   not    | 401    |

  Scenario Outline: Deleting an admin account 
    And there is a user with the following attributes:
      | id | email              | username | password  |
      | 4  | admin2@example.com | admin2   | admin2pwd |
    When the client submits a DELETE request to /users/4 with the <id> user's credentials
    Then the 4th user should be deleted
    And the response should return status 204

    Examples:
      | id  |
      | 4th |
      | 1st |

  Scenario: Deleting the last admin account 
    When the client submits a DELETE request to /users/1 with the 1st user's credentials
    Then the 1st user should not be deleted
    And the response should return status 403
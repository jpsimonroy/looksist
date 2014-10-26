@models
Feature: Lookup model properties

  Scenario: I should be able to inject model properties
    Given I have the following keys setup in Redis
      | key         | value      |
      | employees/1 | Employee 1 |
      | employees/2 | Employee 2 |
      | employees/3 | Employee 3 |
      | employees/4 | Employee 4 |
      | employers/4 | Employee 5 |
    When I create an instance of the "employee" class with id "1"
    Then I model created should have "name" "Employee 1"
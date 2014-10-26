@bucket_lookup
Feature: I should be able to look up all keys in a bucket by pattern so that I can power drop downs with them.

  Scenario: Lookup keys in a bucket by pattern
    Given I have the following keys setup in Redis
      | key                | value |
      | ids/1              | ID 1  |
      | ids/2              | ID 2  |
      | ids/3              | ID 3  |
      | ids/4              | ID 4  |
      | non_matching_ids/4 | ID 4  |
    When I ask looksist to lookup by pattern "id"
    Then I see the response to be the following
      | key   | value |
      | ids/1 | ID 1  |
      | ids/2 | ID 2  |
      | ids/3 | ID 3  |
      | ids/4 | ID 4  |

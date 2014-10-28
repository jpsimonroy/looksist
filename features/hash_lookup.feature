@hashes
Feature: Enrich hashes

  @columnar
  Scenario: I should be able to enrich columnar hashes
    Given I have the following keys setup in Redis
      | key          | value      |
      | employees/10 | Employee 1 |
      | employees/20 | Employee 2 |
      | employees/3  | Employee 3 |
      | employees/4  | Employee 4 |
      | employers/4  | Employee 5 |
    When I ask DeepHash for metrics
    Then I should see the following "employee names" be injected into the hash at "$.table.inner_table"
      | value      |
      | Employee 1 |
      | Employee 2 |

  @object
  Scenario: I should be able to enrich object like hashes
    Given I have the following keys setup in Redis
      | key     | value    |
      | items/1 | Idly     |
      | items/2 | Pongal   |
      | items/3 | Off Menu |
    When I ask Menu for menu
    Then I should see the following "item name" enriched for each sub hash at "$.table.menu"
      | value  |
      | Idly   |
      | Pongal |

  @array_of_hashes
  Scenario: I should be able to enrich an array of hashes
    Given I have the following keys setup in Redis
      | key     | value    |
      | items/1 | Idly     |
      | items/2 | Pongal   |
      | items/3 | Off Menu |
    When I ask ArrayOfHash for menu
    Then I should see the following "item name" in all the hashes
      | value    |
      | Idly     |
      | Pongal   |
      | Off Menu |

When(/^I ask (DeepHash|Menu) for (metrics|menu)$/) do |lookup_service, method|
  @enriched_hash = Object.const_get(lookup_service.classify).new.send(method)
end

Then(/^I should see the following "([^"]*)" be injected into the hash at "([^"]*)"$/) do |target, json_path, table|
  expected_names = table.hashes.collect { |row| row[:value] }
  actual_names = JsonPath.new("#{json_path}.#{target.parameterize.underscore.singularize}").on(@enriched_hash.with_indifferent_access)
  expect(actual_names.size).to eq(1)
  expect(actual_names.first).to eq(expected_names)
end

Then(/^I should see the following "([^"]*)" enriched for each sub hash at "([^"]*)"$/) do |name, jsonpath, table|
  expect(JsonPath.new(jsonpath).on(@enriched_hash.with_indifferent_access).first.collect { |i| i[name.parameterize.underscore.to_sym] }).to eq(table.hashes.collect { |i| i[:value] })
end
Given(/^I have the following keys setup in Redis$/) do |table|
  Looksist.lookup_store.flushall
  table.hashes.each { |row| Looksist.lookup_store.set(row[:key], row[:value]) }
end

When(/^I ask looksist to lookup by pattern "([^"]*)"$/) do |arg|
  @last_response = Looksist.bucket_dump "#{arg}"
end

Then(/^I see the response to be the following$/) do |table|
  expect(table.hashes.each_with_object({}){|row, acc| acc[row[:key]] = row[:value]}).to eq(@last_response)
end
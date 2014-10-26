When(/^I create an instance of the "([^"]*)" class with id "([^"]*)"$/) do |klass, id|
  @model_instance = (Object.const_get klass.classify).new(id)
end

Then(/^I model created should have "([^"]*)" "([^"]*)"$/) do |method, value|
  expect(@model_instance.send(method.to_sym)).to eq(value)
end
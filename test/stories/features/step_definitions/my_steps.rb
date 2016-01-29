Given(/^I visit Homepage$/) do
  visit Homepage
end

Given(/^I visit Properties$/) do
  visit Properties
end

Given(/^I visit For Sale/) do
  visit ForSale
end

Given(/^I visit For Rent$/) do
  visit ForRent
end

Given(/^I visit For Search$/) do
  visit Search
end

Then(/^page is viewable$/) do
  @current_page.assert_page_title
end



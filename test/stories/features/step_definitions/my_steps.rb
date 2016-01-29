Given(/^I am on homepage$/) do
  visit Homepage
end

Then(/^page is viewable$/) do
  @current_page.assert_page_title
end

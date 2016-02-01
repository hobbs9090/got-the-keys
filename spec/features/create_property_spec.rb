#require 'rails_helper'
#
#describe "Creating a new property" do
#
#  include Warden::Test::Helpers  # this will include warden test helper and make login_as and logout method available to you
#  Warden.test_mode!                      # setting warden API to test mode
#
#  it "saves the property and shows the new property's details" do
#
#    login_as 1
#
#    visit new_user_property_path(1)
#
#    expect(current_path).to eq(new_user_property_path(1))
#
#    fill_in "Address line 1", with: "New Property Title"
#    #fill_in "Description", with: "Superheroes saving the world from villains"
#    #select "PG-13", :from => "movie_rating"
#    #fill_in "Total gross", with: "75000000"
#    #select (Time.now.year - 1).to_s, :from => "movie_released_on_1i"
#    #fill_in "Cast", with: "The award-winning cast"
#    #fill_in "Director", with: "The ever-creative director"
#    #fill_in "Duration", with: "123 min"
#    #fill_in "Image file name", with: "movie.png"
#    #
#    #click_button 'Create Property'
#    #
#    #expect(current_path).to eq(movie_path(Movie.last))
#    #
#    #expect(page).to have_text('New Movie Title')
#    #expect(page).to have_text('Movie successfully created!')
#  end
#
#  it "does not save the property if it's invalid" do
#
#    login_as 1
#
#    visit new_user_property_path(1)
#
#    expect(current_path).to eq(new_user_property_path(1))
#
#    expect {
#      click_button 'Create Property'
#    }.not_to change(Property, :count)
#
#    expect(page).to have_text('error')
#  end
#end

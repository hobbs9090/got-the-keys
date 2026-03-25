def property_attributes(overrides = {})
  {
      address_line_1: "Little Orchard",
      address_line_2: "Buckham Thorns Road",
      town_city: "Westerham",
      county: "Kent",
      postcode: "TN16 1ET",
      country: "United Kingdom",
      property_description: "A spacious detached family house recently extended for the current owners.",
      bedrooms: 4,
      sale_status: "For Sale",
      asking_price: 600000.00,
      user_id: 1
  }.merge(overrides)
end

def user_attributes(overrides = {})
  {
      email: "seller01@acme.com",
      first_name: "Test",
      last_name: "User",
      mobile_number: "07595 123456",
      language: "en",
      terms_of_service: "1",
      password: "password",
      password_confirmation: "password"
  }.merge(overrides)
end

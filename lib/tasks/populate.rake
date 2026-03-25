namespace :db do
  desc "Fill database with generated properties"
  task :populate => :environment do
    require 'faker'

    i = 100

    # Faker::Config.locale = 'en-gb'

    start_time = Time.now

    # Create Members and associated properties for sale or rent
    (i).times do
      begin
        User.create!([
                         {
                             first_name: Faker::Name.first_name,
                             last_name: Faker::Name.last_name,
                             language: ['en', 'en', 'en', 'en', 'en', 'zh'].sample,
                             mobile_number: ['07595 123456', '07955 654321', '07955 123123', '+44 7887 112233'].sample,
                             email: Faker::Internet.email,
                             password: "secret",
                             terms_of_service: true
                         }
                     ])
      rescue
        puts User.last
        puts 'Duplicate email address - retrying'
        retry
      end
      [1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5].sample.times do
        sale_type = ["For Sale", "For Sale", "For Rent"].sample
        if sale_type == "For Sale"
          asking_price = [200000.00, 300000.00, 400000.00, 500000.00, 600000.00].sample + [0, 225000.00, 249500, 250000.00, 275000, 295950].sample
        else
          asking_price = [500.00, 750.00, 1000.00, 1250.00, 1500.00].sample + [0, 150.00, 175.00, 225.00, 250.00, 275.00].sample + [0, 25, 50].sample
        end
        Property.create!([
                             {
                                 address_line_1: Faker::Address.street_address,
                                 address_line_2: Faker::Address.secondary_address,
                                 town_city: Faker::Address.city,
                                 county: 'Kent',
                                 postcode: "RH8 9EE",
                                 country: "UK",
                                 property_description: "Sed non distinctio. Dolorem aut sapiente nihil minima nesciunt iusto necessitatibus. Iusto soluta sit alias. Incidunt omnis quis. Tenetur aliquid qui. Voluptatibus blanditiis fugiat. Maiores enim quo ipsum. Assumenda ipsam voluptas voluptate earum sunt.",
                                 bedrooms: [0, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 6].sample,
                                 sale_status: sale_type,
                                 asking_price: asking_price,
                                 user_id: User.last.id
                             }
                         ])
      end
    end

    end_time = Time.now
    puts "Rate of Create: #{i/(end_time - start_time)} sellers/sec"

  end
end

require 'rails_helper'

describe "A user" do

  it "with example attributes is valid" do
    user = User.new(user_attributes)

    expect(user.valid?).to be true
  end

  it "with invalid email is rejected" do
    user = User.new(user_attributes(email: "a@b@c.com"))

    expect(user.valid?).to be false
    expect(user.errors[:email].any?).to be true
    expect(user.errors[:email].first).to eq("is invalid")
  end

  it "requires a given name" do
    user = User.new(user_attributes(first_name: ""))

    expect(user.valid?).to be false
    expect(user.errors[:first_name].any?).to be true
    expect(user.errors[:first_name].first).to eq("can't be blank")
  end

  it "requires last name" do
    user = User.new(user_attributes(last_name: ""))

    expect(user.valid?).to be false
    expect(user.errors[:last_name].any?).to be true
    expect(user.errors[:last_name].first).to eq("can't be blank")
  end

  it "requires a mobile number" do
    user = User.new(user_attributes(mobile_number: ""))

    expect(user.valid?).to be false
    expect(user.errors[:mobile_number].any?).to be true
    expect(user.errors[:mobile_number].first).to eq("can't be blank")
  end

  it "requires a email" do
    user = User.new(user_attributes(email: ""))

    expect(user.valid?).to be false
    expect(user.errors[:email].any?).to be true
    expect(user.errors[:email].first).to eq("can't be blank")
  end

  it "requires a language" do
    user = User.new(user_attributes(language: ""))

    expect(user.valid?).to be false
    expect(user.errors[:language].any?).to be true
    expect(user.errors[:language].first).to eq("can't be blank")
  end

  it "accepts the configured supported languages" do
    language = %w[en de fr it zh]
    language.each do |language|
      user = User.new(user_attributes(language: language))

      expect(user.valid?).to be true
      expect(user.errors[:language].any?).to be false
    end
  end

  it "rejects unsupported language values" do
    language = %w[es zm]
    language.each do |language|
      user = User.new(user_attributes(language: language))

      expect(user.valid?).to be false
      expect(user.errors[:language].any?).to be true
      expect(user.errors[:language].first).to eq("is not included in the list")
    end
  end

  it "requires a password" do
    user = User.new(user_attributes(password: ''))

    expect(user.valid?).to be false
    expect(user.errors[:password].any?).to be true
    expect(user.errors[:password].first).to eq("can't be blank")
  end

  it "must have a password of minimum 6 characters" do
    user = User.new(user_attributes(password: 'X' * 5, password_confirmation: 'X' * 5))

    expect(user.valid?).to be false
    expect(user.errors[:password].any?).to be true
    expect(user.errors[:password].first).to eq("is too short (minimum is 6 characters)")
  end

  it "can have 6 character password" do
    user = User.new(user_attributes(password: 'X' * 6, password_confirmation: 'X' * 6))

    expect(user.valid?).to be true
    expect(user.errors[:password].any?).to be false
  end

  it "rejects an invalid mobile number" do
    user = User.new(user_attributes(mobile_number: "abc"))

    expect(user.valid?).to be false
    expect(user.errors[:mobile_number]).to include("must be a valid phone number")
  end

  it "strips leading and trailing whitespace from form-backed attributes" do
    user = User.new(user_attributes(
      first_name: "  Nina  ",
      last_name: "  Hughes  ",
      mobile_number: "  07595 123456  ",
      email: "  nina.hughes@example.com  ",
      language: "  en  "
    ))

    user.valid?

    expect(user.first_name).to eq("Nina")
    expect(user.last_name).to eq("Hughes")
    expect(user.mobile_number).to eq("07595 123456")
    expect(user.email).to eq("nina.hughes@example.com")
    expect(user.language).to eq("en")
  end

  it "updates associated email-keyed records when the user email changes" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      mobile_number: "07595358089",
      email: "zoe.bates@example.com"
    )
    property = FactoryBot.create(:property)
    rental_property = FactoryBot.create(:property, :for_rent)

    appointment = FactoryBot.create(:appointment, property:, customer_email: user.email.upcase)
    offer = FactoryBot.create(:offer, property:, buyer_email: user.email.upcase)
    rental_application = FactoryBot.create(:rental_application, property: rental_property, applicant_email: user.email.upcase)
    enquiry = FactoryBot.create(:enquiry, property:, customer_email: user.email.upcase)
    saved_search = FactoryBot.create(:saved_search, user:, email: user.email)

    user.update!(email: "zoe.bates+updated@example.com")

    expect(appointment.reload.customer_email).to eq("zoe.bates+updated@example.com")
    expect(offer.reload.buyer_email).to eq("zoe.bates+updated@example.com")
    expect(rental_application.reload.applicant_email).to eq("zoe.bates+updated@example.com")
    expect(enquiry.reload.customer_email).to eq("zoe.bates+updated@example.com")
    expect(saved_search.reload.email).to eq("zoe.bates+updated@example.com")
  end

end

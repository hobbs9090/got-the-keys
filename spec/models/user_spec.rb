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
    expect(user.errors[:language].first).to eq("is not included in the list")
  end

  it "requires language values of 'en' or 'zh'" do
    language = ['en', 'zh']
    language.each do |language|
      user = User.new(user_attributes(language: language))

      expect(user.valid?).to be true
      expect(user.errors[:language].any?).to be false
    end
  end

  it "is rejected for language values of 'fr' or 'zm'" do
    language = ['fr', 'zm']
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

end

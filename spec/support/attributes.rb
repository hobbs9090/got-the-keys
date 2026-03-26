def property_attributes(overrides = {})
  FactoryBot.attributes_for(:property).merge(overrides)
end

def user_attributes(overrides = {})
  FactoryBot.attributes_for(:user).merge(overrides)
end

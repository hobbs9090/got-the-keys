admin_specs = [
  {
    email: 'steven@gotthekeys.com',
    password: 'secret',
    password_confirmation: 'secret',
    language: 'en'
  },
  {
    email: 'stevenhobbs@meeane.co.uk',
    password: 'secret',
    password_confirmation: 'secret',
    language: 'en'
  }
].freeze

demo_user_specs = [
  {
    first_name: 'Steven',
    last_name: 'Sykes',
    mobile_number: '07595 123456',
    email: 'seller01@acme.com',
    password: 'secret',
    password_confirmation: 'secret',
    terms_of_service: true,
    language: 'en'
  },
  {
    first_name: 'Maurice',
    last_name: 'DuBuque',
    mobile_number: '07595 123456',
    email: 'seller02@acme.com',
    password: 'secret',
    password_confirmation: 'secret',
    terms_of_service: true,
    language: 'zh'
  },
  {
    first_name: 'Matt',
    last_name: 'Will',
    mobile_number: '07595 123456',
    email: 'seller03@acme.com',
    password: 'secret',
    password_confirmation: 'secret',
    terms_of_service: true,
    language: 'en'
  },
  {
    first_name: 'Lia',
    last_name: 'McClure',
    mobile_number: '07595 123456',
    email: 'seller04@acme.com',
    password: 'secret',
    password_confirmation: 'secret',
    terms_of_service: true,
    language: 'en'
  }
].freeze

admin_specs.each do |attributes|
  admin = Admin.find_or_initialize_by(email: attributes.fetch(:email))
  admin.assign_attributes(attributes)
  admin.save!
end

demo_users = demo_user_specs.map do |attributes|
  user = User.find_or_initialize_by(email: attributes.fetch(:email))
  user.assign_attributes(attributes)
  user.save!
  user
end

demo_users.each do |user|
  user.properties.destroy_all
end

result = DemoData::Populator.new(
  users: demo_users,
  property_count: Integer(ENV.fetch('SEED_PROPERTIES', 16)),
  password: 'secret',
  ai_mode: DemoData::Populator.ai_mode_from_env(ENV.fetch('SEED_AI_MODE', 'auto')),
  batch_size: Integer(ENV.fetch('OPENAI_SEED_BATCH_SIZE', 4)),
  model: ENV.fetch('OPENAI_SEED_MODEL', DemoData::OpenaiPropertyEnhancer::DEFAULT_MODEL),
  logger: Logger.new($stdout)
).populate!

puts "Seeded #{Admin.count} admins, #{demo_users.count} demo sellers, and #{result.fetch(:properties_created)} demo properties (ai=#{result.fetch(:ai_mode)}, model=#{result.fetch(:model) || 'local'})."

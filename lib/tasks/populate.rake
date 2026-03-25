namespace :db do
  desc "Fill database with generated properties"
  task populate: :environment do
    start_time = Time.current

    result = DemoData::Populator.new(
      user_count: Integer(ENV.fetch('SEED_USERS', DemoData::Populator::DEFAULT_USER_COUNT)),
      property_count: Integer(ENV.fetch('SEED_PROPERTIES', DemoData::Populator::DEFAULT_PROPERTY_COUNT)),
      password: ENV.fetch('SEED_PASSWORD', 'secret'),
      ai_mode: DemoData::Populator.ai_mode_from_env(ENV.fetch('SEED_AI_MODE', 'auto')),
      batch_size: Integer(ENV.fetch('OPENAI_SEED_BATCH_SIZE', DemoData::Populator::DEFAULT_BATCH_SIZE)),
      model: ENV.fetch('OPENAI_SEED_MODEL', DemoData::OpenaiPropertyEnhancer::DEFAULT_MODEL),
      logger: Logger.new($stdout)
    ).populate!

    elapsed = Time.current - start_time

    puts "Generated #{result.fetch(:properties_created)} properties across #{result.fetch(:users_used)} users in #{format('%.2f', elapsed)}s (ai=#{result.fetch(:ai_mode)}, model=#{result.fetch(:model) || 'local'})"
  end
end

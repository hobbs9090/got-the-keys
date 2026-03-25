scenario_key = ENV.fetch("SEED_SCENARIO", "baseline")
summary = DemoData::ScenarioLoader.new.apply_catalog!(key: scenario_key, actor_email: "db:seed")

puts "Loaded demo scenario #{scenario_key.inspect}: #{summary.fetch(:property_count)} properties, #{summary.fetch(:appointment_count)} appointments, #{summary.fetch(:user_count)} sellers."

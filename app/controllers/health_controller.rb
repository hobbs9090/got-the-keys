class HealthController < ActionController::Base
  def show
    checks = {
      database: database_ready?,
      cache: cache_ready?,
      solid_cache: solid_cache_ready?,
      solid_queue: solid_queue_ready?
    }

    if checks.values.all?
      render plain: "OK"
    else
      render plain: failing_checks_message(checks), status: :service_unavailable
    end
  rescue StandardError => error
    render plain: "ERROR: #{error.class}: #{error.message}", status: :service_unavailable
  end

  private

  def database_ready?
    ActiveRecord::Base.connection.select_value("SELECT 1").to_s == "1"
  end

  def cache_ready?
    key = "healthcheck:#{SecureRandom.hex(8)}"
    value = SecureRandom.hex(8)

    Rails.cache.write(key, value, expires_in: 1.minute)
    Rails.cache.read(key) == value
  ensure
    Rails.cache.delete(key) if key.present?
  end

  def solid_cache_ready?
    return true unless solid_cache_configured?

    ActiveRecord::Base.connection.data_source_exists?("solid_cache_entries")
  end

  def solid_queue_ready?
    return true unless solid_queue_configured?

    ActiveRecord::Base.connection.data_source_exists?("solid_queue_jobs")
  end

  def solid_cache_configured?
    Array(Rails.application.config.cache_store).first == :solid_cache_store
  end

  def solid_queue_configured?
    Rails.application.config.active_job.queue_adapter.to_s == "solid_queue"
  end

  def failing_checks_message(checks)
    failed = checks.select { |_name, passed| !passed }.keys

    "FAILED: #{failed.join(', ')}"
  end
end

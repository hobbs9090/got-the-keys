namespace :db do
  desc "Terminate other Postgres sessions for the current database"
  task :terminate_connections => :environment do
    conn = ActiveRecord::Base.connection

    db_name = conn.select_value("SELECT current_database()").to_s
    quoted_db_name = conn.quote(db_name)

    max_attempts = Integer(ENV.fetch("TERMINATE_CONNECTIONS_MAX_ATTEMPTS", "5"))
    sleep_seconds = Float(ENV.fetch("TERMINATE_CONNECTIONS_SLEEP_SECONDS", "1"))

    attempt = 0
    loop do
      other_pids = conn.exec_query(<<~SQL).rows.flatten
        SELECT pid
        FROM pg_stat_activity
        WHERE datname = #{quoted_db_name}
          AND pid <> pg_backend_pid()
      SQL

      if other_pids.empty?
        puts "No other active sessions for database #{db_name}; nothing to terminate."
        break
      end

      puts "Terminating #{other_pids.size} other Postgres session(s) for database #{db_name} (attempt #{attempt + 1}/#{max_attempts})..."

      begin
        conn.exec_query(<<~SQL)
          SELECT pg_terminate_backend(pid)
          FROM pg_stat_activity
          WHERE datname = #{quoted_db_name}
            AND pid <> pg_backend_pid()
        SQL
      rescue PG::InsufficientPrivilege => e
        raise <<~MSG
          Failed to terminate other Postgres sessions (insufficient privilege).

          Postgres error: #{e.class}: #{e.message}

          Deploy runs as: #{ENV["DATABASE_USERNAME"] || "<unknown>"}
          Database: #{db_name}

          To fix: ensure the deploy DB role has pg_signal_backend / sufficient privileges
          for the other sessions, or avoid db:reset on staging.
        MSG
      end

      attempt += 1
      if attempt >= max_attempts
        raise "Postgres still has #{other_pids.size} other active sessions for database #{db_name} after #{max_attempts} attempt(s); aborting db:reset."
      end

      sleep sleep_seconds
    end
  end
end


namespace :deploy do
  desc 'Rebuilds staging database (purge + schema load) and reloads seed data'
  task :reset => [:set_rails_env] do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:terminate_connections"
          # `db:reset` calls `db:drop`, which requires the deploy DB role to be
          # allowed to drop the *database* itself (often not granted on staging).
          # Purge + schema load keeps the "fresh from scratch" behaviour without
          # depending on database-drop privileges.
          execute :rake, "db:purge"
          execute :rake, "db:schema:load"
          execute :rake, "db:seed"
        end
      end
    end
  end
end
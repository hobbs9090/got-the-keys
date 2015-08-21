namespace :deploy do
  desc 'Runs rake db:reset to rebuild database and reload seed data'
  task :reset => [:set_rails_env] do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:reset"
        end
      end
    end
  end
end
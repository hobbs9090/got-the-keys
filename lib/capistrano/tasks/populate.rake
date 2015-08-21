namespace :deploy do
  desc 'Runs rake db:populate to generate data'
  task :populate => [:set_rails_env] do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:populate"
        end
      end
    end
  end
end
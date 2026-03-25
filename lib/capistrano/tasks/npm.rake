namespace :deploy do
  desc 'Install npm dependencies for JS/CSS bundling'
  task :npm_install do
    on roles(:web) do
      within release_path do
        execute :npm, 'ci --no-audit --no-fund'
      end
    end
  end
end

before 'deploy:assets:precompile', 'deploy:npm_install'

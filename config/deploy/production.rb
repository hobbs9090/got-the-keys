server ENV.fetch('DEPLOY_HOST', '192.168.2.204'),
       user: ENV.fetch('DEPLOY_USER', 'deploy'),
       roles: %w[app db web]

set :deploy_to, ENV.fetch('DEPLOY_TO', '/var/www/stevenhobbs.co.uk')
set :rails_env, 'production'
set :default_env, {
  'PATH' => '$HOME/.local/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/bin:/bin'
}

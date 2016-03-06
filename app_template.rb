require 'bundler'

# clean file
run 'rm README.rdoc'

# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token\.rb$/, ''
gsub_file '.gitignore', /^config\/secrets\.yml$/, ''

# Remove puma from Gemfile
gsub_file 'Gemfile', '# Use Puma as the app server'
gsub_file 'Gemfile', "gem 'puma'", ''

# add to Gemfile
append_file 'Gemfile', <<-CODE
# ============================
# View
# ============================
# Bootstrap & Bootswatch & font-awesome
gem 'bootstrap-sass'
gem 'bootswatch-rails'
gem 'font-awesome-rails'

# Fast Haml
gem 'faml'

# Form Builders
gem 'simple_form'

# Pagenation
gem 'kaminari'

# ============================
# Utils
# ============================
# Process Management
gem 'foreman'

# Hash extensions
gem 'hashie'

# Presenter Layer Helper
gem 'cells'

# Table(Migration) Comment
gem 'migration_comments'

# Exception Notifier
gem 'exception_notification'

# Embed the V8 Javascript Interpreter
gem 'therubyracer'

# configuration using ENV
gem 'figaro'

# ============================
# Environment Group
# ============================
group :development do
  gem 'erb2haml'

  # help to kill N+1
  gem 'bullet'

  # Rack Profiler
  # gem 'rack-mini-profiler'
end

group :development, :test do
  # App Server
  gem 'puma'

  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'rb-readline'

  # Show SQL result in Pry console
  gem 'hirb'
  gem 'hirb-unicode'
  gem 'awesome_print'

  # PG/MySQL Log Formatter
  gem 'rails-flog'

  # Assets log cleaner
  gem 'quiet_assets'

  # Rspec
  gem 'rspec-rails'

  # test fixture
  gem 'factory_girl_rails'
end

group :test do
  # Mock for HTTP requests
  gem 'webmock'
  gem 'vcr'

  # Time Mock
  gem 'timecop'

  # Support to generate Test Data
  gem 'faker'

  # Cleaning test data
  gem 'database_rewinder'
end

group :production do
  # App Server
  gem 'unicorn'

  # For Heroku / Dokku
  gem 'rails_12factor'
end
CODE


Bundler.with_clean_env do
  run 'bundle install --path vendor/bundle --jobs=2 --without production'
end

# set config/application.rb
application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    # Set locale
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja

    # Set generator
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs true
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
  }
end

# For Bullet (N+1 Problem)
insert_into_file 'config/environments/development.rb',%(
  # Bullet Setting (help to kill N + 1 query)
  config.after_initialize do
    Bullet.enable = true # enable Bullet gem, otherwise do nothing
    Bullet.alert = true # pop up a JavaScript alert in the browser
    Bullet.console = true #  log warnings to your browser's console.log
    Bullet.rails_logger = true #  add warnings directly to the Rails log
  end
), after: 'config.assets.debug = true'

# Exception Notifier
mail_address = ask("What's your current email address?")
insert_into_file 'config/environments/production.rb',%(
  # Exception Notifier
  Rails.application.config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[#{app_name}] ",
      :sender_address => %{"notifier" <#{mail_address}>},
      :exception_recipients => %w{#{mail_address}}
    }

  # Sanitizing parameter
  config.filter_parameters += [/(password|private_token|api_endpoint)/i]
), after: 'config.active_record.dump_schema_after_migration = false'

# set Japanese locale
get 'https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml', 'config/locales/ja.yml'

# erb => haml
Bundler.with_clean_env do
  run 'bundle exec rake haml:replace_erbs'
end

# Bootstrap/Bootswach/Font-Awesome
run 'rm -rf app/assets/stylesheets/application.css'
get 'https://raw.github.com/morizyun/rails4_template/master/app/assets/stylesheets/application.css.scss', 'app/assets/stylesheets/application.css.scss'

# Initialize SimpleForm
Bundler.with_clean_env do
  run 'bundle exec rails g simple_form:install --bootstrap'
end

# Initialize Kaminari config
Bundler.with_clean_env do
  run 'bundle exec rails g kaminari:config'
end

# Initialize Figaro config
Bundler.with_clean_env do
  run 'bundle exec figaro install'
end

# Unicorn(App Server)
run 'mkdir config/unicorn'
get 'https://raw.github.com/morizyun/rails4_template/master/config/unicorn/development.rb', 'config/unicorn/development.rb'
get 'https://raw.github.com/morizyun/rails4_template/master/config/unicorn/production.rb', 'config/unicorn/production.rb'
run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn/production.rb' > Procfile"

# Rspec
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle exec rails g rspec:install'
end

run "echo '--color -f d' > .rspec"

insert_into_file 'spec/rails_helper.rb',%(
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end

  config.before :all do
    FactoryGirl.reload
    FactoryGirl.factories.clear
    FactoryGirl.sequences.clear
    FactoryGirl.find_definitions
  end

  config.include FactoryGirl::Syntax::Methods

  VCR.configure do |c|
      c.cassette_library_dir = 'spec/vcr'
      c.hook_into :webmock
      c.allow_http_connections_when_no_cassette = true
  end
), after: 'RSpec.configure do |config|'

insert_into_file 'spec/rails_helper.rb', "\nrequire 'factory_girl_rails'", after: "require 'rspec/rails'"
run 'rm -rf test'

# git init
# ----------------------------------------------------------------
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"

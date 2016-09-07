require 'bundler'

# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token\.rb$/, ''
gsub_file '.gitignore', /^config\/secrets\.yml$/, ''

# Ruby Version
ruby_version = `ruby -v`.scan(/\d\.\d\.\d/).flatten.first
insert_into_file 'Gemfile',%(
ruby '#{ruby_version}'
), after: "source 'https://rubygems.org'"
run "echo '#{ruby_version}' > ./.ruby-version"

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

# Presenter Layer Helper
gem 'cells'
gem 'cells-haml'

# Configuration using ENV
gem 'figaro', git: 'https://github.com/morizyun/figaro.git'

# ============================
# Environment Group
# ============================
group :development do
  gem 'erb2haml'

  # help to kill N+1
  gem 'bullet'

  # To generate haml view by scaffold or other generate command
  gem 'haml-rails'

  # Syntax Checker
  # hook event pre-commit, pre-push
  gem 'overcommit', require: false

  # A static analysis security vulnerability scanner
  gem 'brakeman', require: false

  # Checks for vulnerable versions of gems
  gem 'bundler-audit', require: false

  # Style checker that helps keep CoffeeScript code clean and consistent
  gem 'coffeelint', require: false

  # Syntax checker for HAML
  gem 'haml-lint', require: false

  # Syntax checker for CSS
  gem 'ruby_css_lint', require: false

  # A Ruby static code analyzer
  gem 'rubocop', require: false
end

group :development, :test do
  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-byebug'

  # Show SQL result in Pry console
  gem 'hirb'
  gem 'hirb-unicode'
  gem 'awesome_print'

  # PG/MySQL Log Formatter
  gem 'rails-flog'

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

  # This gem brings back assigns to your controller tests
  gem 'rails-controller-testing'
end
CODE

# Error Notification
slack_url = ask('What is a slack hook URL to notify an error in your app?[or just ENTER]')
if !slack_url.nil? && !slack_url.empty?
insert_into_file 'Gemfile',%q{

# Exception Notifier
gem 'exception_notification', git: 'https://github.com/smartinez87/exception_notification.git'
gem 'slack-notifier'
}, after: "gem 'foreman'"

create_file 'config/initializers/exception_notification.rb',%(
require 'exception_notification/rails'

ExceptionNotification.configure do |config|
  config.add_notifier :slack, {
    :webhook_url => "#{slack_url}"
  }
end if Rails.env.production?
)
end

Bundler.with_clean_env do
  run 'bundle install --path vendor/bundle --jobs=4 --without production'
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
insert_into_file 'config/environments/development.rb', %(
  # Bullet Setting (help to kill N + 1 query)
  config.after_initialize do
    Bullet.enable = true # enable Bullet gem, otherwise do nothing
    Bullet.alert = true # pop up a JavaScript alert in the browser
    Bullet.console = true #  log warnings to your browser's console.log
    Bullet.rails_logger = true #  add warnings directly to the Rails log
  end
), after: 'config.assets.debug = true'

# Improve security
insert_into_file 'config/environments/production.rb',%q{

  # Sanitizing parameter
  config.filter_parameters += [/(password|private_token|api_endpoint)/i]
}, after: 'config.active_record.dump_schema_after_migration = false'

# set Japanese locale
get 'https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml', 'config/locales/ja.yml'

# erb => haml
Bundler.with_clean_env do
  run 'bundle exec rake haml:replace_erbs'
end

# Bootstrap/Bootswach/Font-Awesome
run 'rm -rf app/assets/stylesheets/application.css'
get 'https://raw.github.com/morizyun/rails5_application_template/master/app/assets/stylesheets/application.css.scss', 'app/assets/stylesheets/application.css.scss'

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

# Puma(App Server)
run 'mkdir config/puma'
get 'https://raw.github.com/morizyun/rails5_application_template/master/config/puma/production.rb', 'config/puma/production.rb'

# Procfile
run "echo 'web: bundle exec puma -C config/puma/production.rb' > Procfile"

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

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end
  config.include Cell::Testing, type: :cell
), after: 'RSpec.configure do |config|'

insert_into_file 'spec/rails_helper.rb', "\nrequire 'factory_girl_rails'", after: "require 'rspec/rails'"
run 'rm -rf test'

# Checker
# ----------------------------------------------------------------
get 'https://raw.github.com/morizyun/rails5_application_template/master/root/.rubocop.yml', '.rubocop.yml'
get 'https://raw.github.com/morizyun/rails5_application_template/master/root/.overcommit.yml', '.overcommit.yml'
get 'https://raw.github.com/morizyun/rails5_application_template/master/root/.haml-lint.yml', '.haml-lint.yml'

# Rake DB Create
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle exec rake db:create'
end

# Remove Invalid Files
run 'rm -rf ./lib/templates'


# Rubocop Auto correct
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle exec rubocop --auto-correct'
  run 'bundle exec rubocop --auto-gen-config'
end

# Bundler-audit
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle-audit update'
end

# git init
# ----------------------------------------------------------------
git :init
git :add => '.'

# overcommit
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle exec overcommit --sign'
end

# git commit
# ----------------------------------------------------------------
git :commit => "-a -m 'Initial commit'"

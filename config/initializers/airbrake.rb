Airbrake.configure do |config|
  config.host = ENV['AIRBRAKE_HOST']
  config.project_id = 1
  config.project_key = ENV['AIRBRAKE_PROJECT_KEY']
  config.ignore_environments = [:development, :test]
  config.timeout = 120
  config.environment = Rails.env.to_s
end

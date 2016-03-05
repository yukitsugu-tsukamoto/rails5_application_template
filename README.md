# Rails5 application template

Rails5 Application Template. - [Rails Application Templates — Ruby on Rails Guides](http://guides.rubyonrails.org/rails_application_templates.html)

It's easy to start Rails5 application with useful gems.

## Reparation

    brew install wget gibo

## Execution command

Execute following command

    gem update rails

    # if you want to use PostgreSQL, please execute following command;
    bundle exec rails new test_app --database=postgresql --skip-test-unit --skip-bundle -m https://raw.github.com/morizyun/rails4_template/master/app_template.rb

    # if you want to use MySQL, please execute following command;
    bundle exec rails new test_app --database=mysql --skip-test-unit --skip-bundle -m https://raw.github.com/morizyun/rails4_template/master/app_template.rb

## Detail explanation

Description of this template in Japanese is as follows;

**[Rails 5.0.0 + Bootstrap 1コマンドで！](http://morizyun.github.io/blog/rails5-application-templates/)**

## Supported versions

- Ruby 2.3.0
- Rails 5.0.0.beta3

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

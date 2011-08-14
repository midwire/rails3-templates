remove_file "README"
remove_file "public/index.html"
remove_file "app/views/layouts/application.html.erb"
remove_file 'public/images/rails.png'

inject_into_file 'config/application.rb', :after => "config.filter_parameters += [:password]" do
  <<-EOF
\n
    # Customize generators
    config.generators do |g|
      g.stylesheets false
      g.form_builder :simple_form
      g.test_framework :rspec
      g.fallbacks[:rspec] = :shoulda
      g.fallbacks[:shoulda] = :test_unit
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end
  EOF
end

append_file "Gemfile", <<-END

gem 'haml', '>= 3.0.0'
gem 'haml-rails'
gem "compass", ">= 0.11.3"
gem 'jquery-rails'
gem 'simple_form'

group :development do
  gem "rails3-generators"
  gem "rails-erd"
  gem "nifty-generators", "~> 0.4.2"
  gem "ruby-prof"
  gem "erb2haml"
end

group :development, :test do
  gem "rspec-rails", ">= 2.0.1"
  gem "factory_girl_rails"
  gem 'cucumber-rails'
  gem 'capybara'
end

group :test do
  gem "forgery", :git => 'git://github.com/midwire/forgery.git'
  gem "autotest"
end
END

# Setup RVM and Gemset
current_ruby_full = %x{rvm list}.match(/^=>\s+(.*)\s\[/)[1].strip
current_ruby = current_ruby_full.gsub(/ruby\-/, '')
create_file ".rvmrc", <<-END
#!/usr/bin/env bash

# This is an RVM Project .rvmrc file, used to automatically load the ruby
# development environment upon cd'ing into the directory

# First we specify our desired <ruby>[@<gemset>], the @gemset name is optional.
environment_id="ruby-1.8.7-p334@#{app_name}"

#
# First we attempt to load the desired environment directly from the environment
# file. This is very fast and efficicent compared to running through the entire
# CLI and selector. If you want feedback on which environment was used then
# insert the word 'use' after --create as this triggers verbose mode.
#
if [[ -d "${rvm_path:-$HOME/.rvm}/environments" \
  && -s "${rvm_path:-$HOME/.rvm}/environments/$environment_id" ]] ; then
  \. "${rvm_path:-$HOME/.rvm}/environments/$environment_id"

  [[ -s ".rvm/hooks/after_use" ]] && . ".rvm/hooks/after_use"
else
  # If the environment file has not yet been created, use the RVM CLI to select.
  rvm --create  "$environment_id"
fi
END
run ". .rvmrc; rvm gemset create #{app_name}"
run ". .rvmrc; gem install bundler --no-rdoc --no-ri"
run ". .rvmrc; bundle install"
run ". .rvmrc; rake db:create"

# Generators
run ". .rvmrc; rails generate nifty:layout --haml"
run ". .rvmrc; rails generate simple_form:install"
run ". .rvmrc; rails generate nifty:config"
run '. .rvmrc; rails generate jquery:install --ui'
run '. .rvmrc; rails generate rspec:install'
inject_into_file 'spec/spec_helper.rb', "\nrequire 'factory_girl'", :after => "require 'rspec/rails'"
run "compass create . --using blueprint --syntax scss --css-dir 'public/stylesheets' --sass-dir 'app/stylesheets' --app rails"
run "compass install blueprint"
run "echo '--format documentation' >> .rspec"

inject_into_file 'app/views/layouts/application.html.haml', :before => '    = stylesheet_link_tag "application"' do
  <<-EOF
    = stylesheet_link_tag 'screen.css', :media => 'screen, projection'
    = stylesheet_link_tag 'print.css', :media => 'print'
    /[if lt IE 8]
      = stylesheet_link_tag 'ie.css', :media => 'screen, projection'
EOF
end

# GIT
append_file ".gitignore", <<-GIT
config/database.yml
tmp/**/*
log/*.pid
.DS_Store
public/system
coverage/
test/fixtures
GIT

create_file "log/.gitkeep"
create_file "tmp/.gitkeep"

git :init
git :add => "."
git :commit => '-m "Initial import."'

puts <<-NOTES
Party On!!!
NOTES

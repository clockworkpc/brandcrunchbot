def rspec_files(rspec)
  # RSpec files
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)
end

def ruby_files(dsl, ruby)
  # Ruby files
  dsl.watch_spec_files_for(ruby.lib_files)
end

def rails_files(dsl, rails)
  # Rails files
  dsl.watch_spec_files_for(rails.app_files)
  dsl.watch_spec_files_for(rails.views)

  watch(rails.controllers) do |m|
    [
      rspec.spec.call("routing/#{m[1]}_routing"),
      rspec.spec.call("controllers/#{m[1]}_controller"),
      rspec.spec.call("acceptance/#{m[1]}")
    ]
  end
end

def rails_config_changes(rails)
  # Rails config changes
  watch(rails.spec_helper)     { rspec.spec_dir }
  watch(rails.routes)          { "#{rspec.spec_dir}/routing" }
  watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }
end

def capybara_features_and_specs(rails)
  # Capybara features specs
  watch(rails.view_dirs)     { |m| rspec.spec.call("features/#{m[1]}") }
  watch(rails.layouts)       { |m| rspec.spec.call("features/#{m[1]}") }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$}) do |m|
    Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance'
  end
end

def guard_settings
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)
  rails = dsl.rails(view_extensions: %w[erb haml slim])
  rspec = dsl.rspec
  ruby = dsl.ruby
  rspec_files(rspec)
  ruby_files(dsl, ruby)
  rails_files(dsl, rails)
  rails_config_changes(rails)
  capybara_features_and_specs(rails)
end

group :focus do
  guard :rspec, cmd: 'bundle exec rspec --color --format doc --tag focus' do
    guard_settings
  end
end

group :default do
  guard :rspec, cmd: 'bundle exec rspec --color --format doc' do
    guard_settings
  end
end

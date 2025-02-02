# frozen_string_literal: true

# It is advised to load simplecov before everything else
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter 'lib/sdr_client/cli.rb'
  add_filter 'lib/sdr_client/cli/'
  add_filter 'lib/sdr_client/redesigned_client/cli.rb'
  add_filter 'lib/sdr_client/redesigned_client/cli/'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

require 'bundler/setup'
require 'sdr_client'
require 'cocina/rspec'
require 'byebug'
require 'webmock/rspec'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

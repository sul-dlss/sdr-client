# frozen_string_literal: true

require 'zeitwerk'
# Zeitwerk doesn't auto-load these dependencies
require 'dry/monads'
require 'faraday'
require 'active_support'
require 'active_support/core_ext'
require 'cocina/models'

loader = Zeitwerk::Loader.for_gem
loader.ignore(
  "#{__dir__}/sdr-client.rb",
  "#{__dir__}/sdr_client/cli.rb",
  "#{__dir__}/sdr_client/cli",
  "#{__dir__}/sdr_client/redesigned_client/cli.rb",
  "#{__dir__}/sdr_client/redesigned_client/cli"
)
loader.inflector.inflect(
  'md5' => 'MD5',
  'sha1' => 'SHA1'
)
loader.setup

module SdrClient
  class Error < StandardError; end
  # Your code goes here...
end

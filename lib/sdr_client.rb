# frozen_string_literal: true

require 'dry/monads'
require 'faraday'
require 'active_support'
require 'active_support/core_ext'
require 'cocina/models'

require 'sdr_client/version'
require 'sdr_client/unexpected_response'
require 'sdr_client/deposit'
require 'sdr_client/update'
require 'sdr_client/credentials'
require 'sdr_client/find'
require 'sdr_client/login'
require 'sdr_client/login_prompt'
require 'sdr_client/connection'
require 'sdr_client/background_job_results'

module SdrClient
  class Error < StandardError; end
  # Your code goes here...
end

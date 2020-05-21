# frozen_string_literal: true

require 'dry/monads'
require 'faraday'
require 'active_support'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/hash/indifferent_access'
require 'cocina/models'

require 'sdr_client/version'
require 'sdr_client/deposit'
require 'sdr_client/model_deposit'
require 'sdr_client/credentials'
require 'sdr_client/login'
require 'sdr_client/login_prompt'
require 'sdr_client/cli'
require 'sdr_client/connection'
require 'sdr_client/background_job_results'

module SdrClient
  class Error < StandardError; end
  # Your code goes here...
end

# frozen_string_literal: true

require 'dry/monads'
require 'faraday'

require 'sdr_client/version'
require 'sdr_client/deposit'
require 'sdr_client/model_deposit'
require 'sdr_client/credentials'
require 'sdr_client/login'
require 'sdr_client/login_prompt'
require 'sdr_client/cli'

module SdrClient
  class Error < StandardError; end
  # Your code goes here...
end

# frozen_string_literal: true

require 'digest'
require 'logger'
require 'shellwords'
require 'singleton'
require 'timeout'

module SdrClient
  # The SDR client reimagined, built using patterns successfully used in other client gems we maintain
  class RedesignedClient
    include Singleton

    class << self
      # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      def configure(url:, email: nil, password: nil, token_refresher: nil, token: default_token,
                    request_options: default_request_options, logger: default_logger)
        if email.blank? && password.blank? && !token_refresher.respond_to?(:call)
          raise ArgumentError, 'email and password cannot be blank without a custom token refresher callable'
        end

        instance.config = Config.new(
          token: token,
          url: url,
          email: email,
          password: password,
          request_options: request_options,
          logger: logger,
          token_refresher: token_refresher
        )

        instance
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

      # For the initial token, use a dummy value to avoid hitting any APIs
      # during configuration, allowing `with_token_refresh_when_unauthorized` to handle
      # auto-magic token refreshing. Why not immediately get a valid token? Our apps
      # commonly invoke client `.configure` methods in the initializer in all
      # application environments, even those that are never expected to
      # connect to production APIs, such as local development machines.
      #
      # NOTE: `nil` and blank string cannot be used as dummy values here as
      # they lead to a malformed request to be sent, which triggers an
      # exception not rescued by `with_token_refresh_when_unauthorized`
      def default_token
        'a temporary dummy token to avoid hitting the API before it is needed'
      end

      def default_logger
        Logger.new($stdout)
      end

      def default_request_options
        {
          read_timeout: default_timeout,
          timeout: default_timeout
        }
      end

      # NOTE: This is the number of seconds it roughly takes for H2 to
      #       successfully shunt ~10GB files over to SDR API
      def default_timeout
        900
      end

      delegate :config, :connection, :deposit_model, :job_status, :find, :update_model, :build_and_deposit,
               to: :instance
    end

    attr_accessor :config

    def deposit_model(...)
      Deposit.deposit_model(...)
    end

    def job_status(...)
      JobStatus.new(...)
    end

    def find(...)
      Find.run(...)
    end

    def update_model(...)
      UpdateResource.run(...)
    end

    def build_and_deposit(...)
      Metadata.deposit(...)
    end

    # Send an authenticated GET request
    # @param path [String] the path to the SDR API request
    def get(path:)
      response = with_token_refresh_when_unauthorized do
        connection.get(path)
      end

      UnexpectedResponse.call(response) unless response.success?

      return nil if response.body.blank?

      JSON.parse(response.body).with_indifferent_access
    end

    # Send an authenticated POST request
    # @param path [String] the path to the SDR API request
    # @param body [String] the body of the SDR API request
    # @param headers [Hash] extra headers to add to the SDR API request
    # @param expected_status [Integer] override if all 2xx statuses aren't success conditions
    def post(path:, body:, headers: {}, expected_status: nil) # rubocop:disable Metrics/MethodLength
      response = with_token_refresh_when_unauthorized do
        connection.post(path) do |request|
          request.body = body
          request.headers = default_headers.merge(headers)
        end
      end

      if expected_status
        UnexpectedResponse.call(response) if response.status != expected_status
      elsif !response.success?
        UnexpectedResponse.call(response)
      end

      return nil if response.body.blank?

      JSON.parse(response.body).with_indifferent_access
    end

    # Send an authenticated PUT request
    # @param path [String] the path to the SDR API request
    # @param body [String] the body of the SDR API request
    # @param headers [Hash] extra headers to add to the SDR API request
    # @param params [Hash] query parameters to add to the SDR API request
    # @param expected_status [Integer] override if all 2xx statuses aren't success conditions
    def put(path:, body:, headers: {}, params: {}, expected_status: nil) # rubocop:disable Metrics/MethodLength
      response = with_token_refresh_when_unauthorized do
        connection.put(path) do |request|
          request.body = body
          request.headers = default_headers.merge(headers)
          request.params = params if params.present?
        end
      end

      if expected_status
        UnexpectedResponse.call(response) if response.status != expected_status
      elsif !response.success?
        UnexpectedResponse.call(response)
      end

      return nil if response.body.blank?

      JSON.parse(response.body).with_indifferent_access
    end

    private

    Config = Struct.new(:url, :email, :password, :token, :logger,
                        :request_options, :token_refresher, keyword_init: true)

    def connection
      Faraday.new(
        url: SdrClient::RedesignedClient.config.url,
        headers: default_headers,
        request: SdrClient::RedesignedClient.config.request_options
      ) do |conn|
        conn.adapter :net_http
      end
    end

    def default_headers
      {
        accept: 'application/json',
        content_type: 'application/json',
        Authorization: "Bearer #{config.token}"
      }
    end

    def with_token_refresh_when_unauthorized
      response = yield

      # if unauthorized, token has likely expired. try to get a new token and then retry the same request(s).
      if response.status == 401
        config.token = config.token_refresher ? config.token_refresher.call : Authenticator.token
        response = yield
      end

      response
    end
  end
end

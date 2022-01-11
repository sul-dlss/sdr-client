# frozen_string_literal: true

module SdrClient
  # The connection to the server
  class Connection
    include Dry::Monads[:result]

    # @param [Integer] read_timeout the value in seconds to set the read timeout
    def initialize(url:, token: Credentials.read, read_timeout: 360)
      @url = url
      @token = token
      @request_options = { read_timeout: read_timeout }
    end

    def connection
      @connection ||= Faraday.new(url: url, request: request_options) do |conn|
        conn.request :authorization, :Bearer, token
        conn.adapter :net_http
      end
    end

    # This is only available to certain blessed accounts (argo) as it gives the
    # token that allows you to act as any other user. Thus the caller must authenticate
    # the user (e.g. using Shibboleth) before calling this method with their email address.
    # @param [String] the email address of the person to proxy to.
    # @return [Result] the token for the account
    def proxy(to)
      response = connection.post("/v1/auth/proxy?to=#{to}")
      case response.status
      when 200
        Success(response.body)
      else
        Failure("Status: #{response.status}\n#{response.body}")
      end
    end

    delegate :put, :post, :get, to: :connection

    private

    attr_reader :url, :token, :request_options
  end
end

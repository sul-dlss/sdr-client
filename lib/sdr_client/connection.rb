# frozen_string_literal: true

module SdrClient
  # The connection to the server
  class Connection
    def initialize(url:, token: Credentials.read)
      @url = url
      @token = token
    end

    def connection
      @connection ||= Faraday.new(url: url) do |conn|
        conn.authorization :Bearer, token
        conn.adapter :net_http
      end
    end

    delegate :put, :post, to: :connection

    private

    attr_reader :url, :token
  end
end

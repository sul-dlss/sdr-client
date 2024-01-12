# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Fetch a token from the SDR API using user credentials
    class Authenticator
      def self.token
        new.token
      end

      # Request an access_token
      def token
        response = connection.post(path, request_body)

        UnexpectedResponse.call(response) unless response.success?

        JSON.parse(response.body)['token']
      end

      private

      def request_body
        JSON.generate(
          {
            email: SdrClient::RedesignedClient.config.email,
            password: SdrClient::RedesignedClient.config.password
          }
        )
      end

      def path
        '/v1/auth/login'
      end

      def connection
        Faraday.new(url: SdrClient::RedesignedClient.config.url)
      end
    end
  end
end

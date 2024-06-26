# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Handles unexpected responses
    class UnexpectedResponse
      # Raised when there is a request error (e.g.: a cocina-models version mismatch)
      class BadRequest < StandardError; end
      # Raised when there is a problem with the credentials
      class Unauthorized < StandardError; end

      # @param [Faraday::Response] response
      def self.call(response)
        case response.status
        when 400
          raise BadRequest, "There was an error with your request: #{response.body}"
        when 401
          raise Unauthorized, 'There was an error with your credentials.'
        else
          raise "unexpected response: #{response.status} #{response.body}"
        end
      end
    end
  end
end

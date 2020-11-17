# frozen_string_literal: true

module SdrClient
  module Deposit
    # Handles unexpected responses when manipulating resources
    class UnexpectedResponse
      # @param [Faraday::Response] response
      def self.call(response)
        raise "There was an error with your request: #{response.body}" if response.status == 400
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.status} #{response.body}"
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  module Deposit
    # Updates a resource (metadata) in SDR
    class UpdateResource
      DRO_PATH = '/v1/resources/%<id>s'

      def self.run(metadata:, logger:, connection:)
        new(metadata: metadata, logger: logger, connection: connection).run
      end

      # @param [Cocina::Models::DRO] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      def initialize(metadata:, logger:, connection:)
        @metadata = metadata
        @logger = logger
        @connection = connection
      end

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @return [String] job id for the background job result
      def run
        response = metadata_request
        unexpected_response(response) unless response.status == 200

        logger.info("Response from server: #{response.body}")

        JSON.parse(response.body)['jobId']
      end

      private

      attr_reader :metadata, :logger, :connection

      def metadata_request
        json = metadata.to_json
        logger.debug("Starting upload metadata: #{json}")

        connection.put(path(metadata), json, 'Content-Type' => 'application/json')
      end

      def unexpected_response(response)
        raise "There was an error with your request: #{response.body}" if response.status == 400
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.status} #{response.body}"
      end

      def path(metadata)
        format(DRO_PATH, id: metadata.externalIdentifier)
      end
    end
  end
end

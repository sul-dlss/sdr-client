# frozen_string_literal: true

module SdrClient
  module Deposit
    # Uploads a resource (metadata) to the server
    class UploadResource
      DRO_PATH = '/v1/resources'

      def self.run(accession:, metadata:, logger:, connection:)
        new(accession: accession, metadata: metadata, logger: logger, connection: connection).run
      end

      # @param [Boolean] accession should the accessionWF be started
      # @param [String] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      def initialize(accession:, metadata:, logger:, connection:)
        @accession = accession
        @metadata = metadata
        @logger = logger
        @connection = connection
      end

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @return [Hash<Symbol,String>] the result of the metadata call
      def run
        response = metadata_request
        unexpected_response(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        { druid: JSON.parse(response.body)['druid'], background_job: response.headers['Location'] }
      end

      private

      attr_reader :metadata, :logger, :connection

      def metadata_request
        logger.debug("Starting upload metadata: #{metadata}")

        connection.post(path, metadata, 'Content-Type' => 'application/json')
      end

      def unexpected_response(response)
        raise "There was an error with your request: #{response.body}" if response.status == 400
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.status} #{response.body}"
      end

      def accession?
        @accession
      end

      def path
        path = DRO_PATH
        path += '?accession=true' if accession?
        path
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  module Deposit
    # Creates a resource (metadata) in SDR
    class CreateResource
      DRO_PATH = '/v1/resources'

      def self.run(accession:, metadata:, logger:, connection:)
        new(accession: accession, metadata: metadata, logger: logger, connection: connection).run
      end

      # @param [Boolean] accession should the accessionWF be started
      # @param [Cocina::Models::RequestDRO, Cocina::Models::RequestCollection] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      def initialize(accession:, metadata:, logger:, connection:)
        @accession = accession
        @metadata = metadata
        @logger = logger
        @connection = connection
      end

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @return [String] job id for the background job result
      def run
        response = metadata_request
        UnexpectedResponse.call(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        JSON.parse(response.body)['jobId']
      end

      private

      attr_reader :metadata, :logger, :connection

      def metadata_request
        json = metadata.to_json
        logger.debug("Starting upload metadata: #{json}")

        connection.post(path, json, 'Content-Type' => 'application/json')
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

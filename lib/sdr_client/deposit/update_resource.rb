# frozen_string_literal: true

module SdrClient
  module Deposit
    # Updates a resource (metadata) in SDR
    class UpdateResource
      DRO_PATH = '/v1/resources/%<id>s'

      def self.run(metadata:, logger:, connection:, version_description: nil)
        new(metadata: metadata, logger: logger, connection: connection, version_description: version_description).run
      end

      # @param [Cocina::Models::DRO] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      # @param [String] version_description
      def initialize(metadata:, logger:, connection:, version_description: nil)
        @metadata = metadata
        @logger = logger
        @connection = connection
        @version_description = version_description
      end

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @return [String] job id for the background job result
      def run
        response = metadata_request
        UnexpectedResponse.call(response) unless response.status == 202

        logger.info("Response from server: #{response.body}")

        JSON.parse(response.body)['jobId']
      end

      private

      attr_reader :metadata, :logger, :connection, :version_description

      def metadata_request
        json = metadata.to_json
        logger.debug("Starting update metadata: #{json}")

        connection.put(path(metadata), json,
                       'Content-Type' => 'application/json',
                       'X-Cocina-Models-Version' => Cocina::Models::VERSION) do |req|
                         req.params['versionDescription'] = version_description if version_description
                       end
      end

      def path(metadata)
        format(DRO_PATH, id: metadata.externalIdentifier)
      end
    end
  end
end

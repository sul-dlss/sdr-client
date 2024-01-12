# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Updates a resource (metadata) in SDR
    class UpdateResource
      RESOURCE_PATH = '/v1/resources/%<id>s'

      def self.run(...)
        new(...).run
      end

      # @param [Cocina::Models::DRO] model
      # @param [String] version_description
      def initialize(model:, version_description: nil)
        @model = model
        @version_description = version_description
      end

      # @return [String] job id for the background job result
      def run # rubocop:disable Metrics/MethodLength
        json = model.to_json
        logger.debug("Starting update with model: #{json}")

        response_hash = client.put(
          path: path,
          body: json,
          headers: { 'X-Cocina-Models-Version' => Cocina::Models::VERSION },
          params: request_params,
          expected_status: 202
        )

        logger.info("Response from server: #{response_hash}")

        response_hash.fetch('jobId')
      end

      private

      attr_reader :model, :version_description

      def client
        SdrClient::RedesignedClient.instance
      end

      def logger
        SdrClient::RedesignedClient.config.logger
      end

      def path
        format(RESOURCE_PATH, id: model.externalIdentifier)
      end

      def request_params
        return { 'versionDescription' => version_description } if version_description

        {}
      end
    end
  end
end

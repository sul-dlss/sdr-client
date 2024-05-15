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
      # @param [String] user_versions action (none, new, update) to take for user version when closing version
      def initialize(model:, version_description: nil, user_versions: nil)
        @model = model
        @version_description = version_description
        @user_versions = user_versions
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

      attr_reader :model, :version_description, :user_versions

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
        {
          versionDescription: version_description,
          user_versions: user_versions
        }.compact
      end
    end
  end
end

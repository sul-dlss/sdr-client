# frozen_string_literal: true

module SdrClient
  module Deposit
    # Updates a resource (metadata) in SDR
    class UpdateResource
      DRO_PATH = '/v1/resources/%<id>s'

      def self.run(...)
        new(...).run
      end

      # @param [Cocina::Models::DRO] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      # @param [String] version_description
      # @param [String] user_versions action (none, new, update) to take for user version when closing version
      # @param [Boolean] accession true if accessioning should be performed
      def initialize(metadata:, logger:, connection:, version_description: nil, user_versions: nil, accession: true) # rubocop:disable Metrics/ParameterLists
        @metadata = metadata
        @logger = logger
        @connection = connection
        @version_description = version_description
        @user_versions = user_versions
        @accession = accession
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

      attr_reader :metadata, :logger, :connection, :version_description, :user_versions, :accession

      # rubocop:disable Metrics/AbcSize
      def metadata_request
        json = metadata.to_json
        logger.debug("Starting update metadata: #{json}")

        connection.put(path(metadata), json,
                       'Content-Type' => 'application/json',
                       'X-Cocina-Models-Version' => Cocina::Models::VERSION) do |req|
                         req.params['versionDescription'] = version_description if version_description
                         req.params['user_versions'] = user_versions if user_versions.present?
                         req.params['accession'] = true if accession
                       end
      end
      # rubocop:enable Metrics/AbcSize

      def path(metadata)
        format(DRO_PATH, id: metadata.externalIdentifier)
      end
    end
  end
end

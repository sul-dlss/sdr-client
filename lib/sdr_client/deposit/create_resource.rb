# frozen_string_literal: true

module SdrClient
  module Deposit
    # Creates a resource (metadata) in SDR
    class CreateResource
      DRO_PATH = '/v1/resources'
      def self.run(...)
        new(...).run
      end

      # @param [Boolean] accession should the accessionWF be started
      # @param [Boolean] assign_doi should a DOI be assigned to this item
      # @param [Cocina::Models::RequestDRO, Cocina::Models::RequestCollection] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      # @param [String] priority what processing priority should be used
      #                          either 'low' or 'default'
      # @param [String] user_versions action (none, new, update) to take for user version when closing version
      # rubocop:disable Metrics/ParameterLists
      def initialize(accession:, metadata:, logger:, connection:, assign_doi: false, priority: nil, user_versions: nil)
        @accession = accession
        @priority = priority
        @assign_doi = assign_doi
        @metadata = metadata
        @logger = logger
        @connection = connection
        @user_versions = user_versions
      end
      # rubocop:enable Metrics/ParameterLists

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @return [String] job id for the background job result
      def run
        response = metadata_request
        UnexpectedResponse.call(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        JSON.parse(response.body)['jobId']
      end

      private

      attr_reader :metadata, :logger, :connection, :priority, :user_versions

      def metadata_request
        json = metadata.to_json
        logger.debug("Starting upload metadata: #{json}")

        connection.post(path, json,
                        'Content-Type' => 'application/json',
                        'X-Cocina-Models-Version' => Cocina::Models::VERSION)
      end

      def accession?
        @accession
      end

      def assign_doi?
        @assign_doi
      end

      def path
        params = { accession: accession? }
        params[:priority] = priority if priority
        params[:assign_doi] = true if assign_doi? # false is default
        params[:user_versions] = user_versions if user_versions.present?
        DRO_PATH + '?' + params.map { |k, v| "#{k}=#{v}" }.join('&')
      end
    end
  end
end

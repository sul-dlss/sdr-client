# frozen_string_literal: true

module SdrClient
  module Deposit
    # Creates a resource (metadata) in SDR
    class CreateResource
      DRO_PATH = '/v1/resources'

      def self.run(accession:, assign_doi: false, metadata:, logger:, connection:)
        new(accession: accession,
            assign_doi: assign_doi,
            metadata: metadata,
            logger: logger,
            connection: connection).run
      end

      # @param [Boolean] accession should the accessionWF be started
      # @param [Boolean] assign_doi should a DOI be assigned to this item
      # @param [Cocina::Models::RequestDRO, Cocina::Models::RequestCollection] metadata
      # @param [Hash<Symbol,String>] the result of the metadata call
      def initialize(accession:, assign_doi:, metadata:, logger:, connection:)
        @accession = accession
        @assign_doi = assign_doi
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
        params[:assign_doi] = true if assign_doi? # false is default
        DRO_PATH + '?' + params.map { |k, v| "#{k}=#{v}" }.join('&')
      end
    end
  end
end

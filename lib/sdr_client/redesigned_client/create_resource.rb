# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Creates a resource (metadata) in SDR
    class CreateResource
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
      def initialize(accession:, metadata:, assign_doi: false, priority: nil, user_versions: nil)
        @accession = accession
        @priority = priority
        @assign_doi = assign_doi
        @metadata = metadata
        @user_versions = user_versions
      end

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @return [String] job id for the background job result
      def run
        json = metadata.to_json
        logger.debug("Starting upload metadata: #{json}")

        response_hash = client.post(
          path: path,
          body: json,
          headers: { 'X-Cocina-Models-Version' => Cocina::Models::VERSION },
          expected_status: 201
        )

        logger.info("Response from server: #{response_hash.to_json}")

        response_hash.fetch(:jobId)
      end

      private

      attr_reader :metadata, :priority, :user_versions

      def logger
        SdrClient::RedesignedClient.config.logger
      end

      def client
        SdrClient::RedesignedClient.instance
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
        query_string = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "/v1/resources?#{query_string}"
      end
    end
  end
end

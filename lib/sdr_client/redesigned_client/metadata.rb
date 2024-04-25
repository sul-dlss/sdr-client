# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Build an object and then deposit it
    class Metadata
      def self.deposit(...)
        new(...).deposit
      end

      # @param [String] apo object ID (druid) of the admin policy/APO
      # @param [String] basepath the base path of the files (to make relative paths absolute)
      # @param [String] source_id source ID
      # @param [Hash] options optional parameters
      # @option options [Array<String>] files a list of relative filepaths to upload
      # @option options [Hash<String, Hash<String, String>>] files_metadata file name, hash of additional file metadata
      def initialize(apo:, basepath:, source_id:, **options)
        @apo = apo
        @basepath = basepath
        @source_id = source_id
        @options = options
      end

      def deposit # rubocop:disable Metrics/MethodLength
        structural_metadata = SdrClient::RedesignedClient::StructuralMetadataBuilder.build(
          files: files, files_metadata: files_metadata, basepath: basepath
        )
        request_builder = SdrClient::RedesignedClient::RequestBuilder.new(
          apo: apo,
          source_id: source_id,
          files_metadata: structural_metadata,
          **options
        )
        client.deposit_model(
          model: request_builder.to_cocina,
          basepath: basepath,
          files: files,
          accession: accession,
          request_builder: request_builder,
          **options
        )
      end

      private

      attr_reader :apo, :basepath, :source_id, :options

      def client
        SdrClient::RedesignedClient.instance
      end

      def files
        options.fetch(:files, [])
      end

      def files_metadata
        options.fetch(:files_metadata, {})
      end

      def accession
        options.fetch(:accession, false)
      end
    end
  end
end

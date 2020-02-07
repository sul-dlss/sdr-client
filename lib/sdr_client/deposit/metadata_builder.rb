# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # Constructs the deposit metadata for the DRO
    class MetadataBuilder
      # @param [Request] metadata information about the object
      # @param [Class] grouping_strategy class whose run method groups an array of uploads
      # Additional metadata includes access, preserve, shelve, md5, sha1
      # @param [Logger] logger the logger to use
      def initialize(metadata:, grouping_strategy:, logger:)
        @metadata = metadata
        @logger = logger
        @grouping_strategy = grouping_strategy
      end

      def with_uploads(upload_responses)
        file_sets = build_filesets(uploads: upload_responses)
        metadata.with_file_sets(file_sets)
      end

      private

      attr_reader :metadata, :files, :logger, :grouping_strategy

      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<SdrClient::Deposit::FileSet>] the uploads transformed to filesets
      def build_filesets(uploads:)
        grouped_uploads = grouping_strategy.run(uploads: uploads)
        grouped_uploads.map.with_index(1) do |upload_group, i|
          metadata_group = {}
          upload_group.each { |upload| metadata_group[upload.filename] = metadata.for(upload.filename) }
          FileSet.new(uploads: upload_group, uploads_metadata: metadata_group, label: "Object #{i}")
        end
      end
    end
  end
end
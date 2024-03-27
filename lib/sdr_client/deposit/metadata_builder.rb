# frozen_string_literal: true

module SdrClient
  module Deposit
    # Constructs the deposit metadata for the DRO
    class MetadataBuilder
      # @param [Request] metadata information about the object
      # @param [Class] grouping_strategy class whose run method groups an array of uploads
      # Additional metadata includes access, preserve, shelve, publish, md5, sha1
      # @param [Logger] logger the logger to use
      # @param [Class] file_set_type_strategy class whose run method determines file_set type
      def initialize(metadata:, grouping_strategy:, logger:, file_set_type_strategy: FileTypeFileSetStrategy)
        @metadata = metadata
        @logger = logger
        @grouping_strategy = grouping_strategy
        @file_set_type_strategy = file_set_type_strategy
      end

      # @param [UploadFiles] upload_responses the uploaded file information
      # @return [Request] the metadata with fileset information added in.
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
          FileSet.new(uploads: upload_group,
                      uploads_metadata: metadata_group(upload_group),
                      label: label(i),
                      type_strategy: @file_set_type_strategy)
        end
      end

      def label(index)
        case metadata.type
        when BOOK_TYPE
          "Page #{index}"
        else
          "Object #{index}"
        end
      end

      # Get the metadata for the files belonging to a fileset
      def metadata_group(upload_group)
        upload_group.each_with_object({}) do |upload, obj|
          obj[upload.filename] = metadata.for(upload.filename)
        end
      end
    end
  end
end

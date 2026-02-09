# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Builds and constructs the structural metadata given upload responses (file
    # IDs, file set grouping strategies, etc.)
    class StructuralGrouper
      def self.group(...)
        new(...).group
      end

      # @param [RequestBuilder] request_biulder a request builder instance
      # @param [Array<DirectUploadResponse>] upload_responses upload response instances
      # @param [String] grouping_strategy what strategy will be used to group files
      # @param [String] file_set_strategy what strategy will be used to group file sets
      def initialize(request_builder:, upload_responses:, grouping_strategy:, file_set_strategy: nil) # rubocop:disable Metrics/MethodLength
        @request_builder = request_builder
        @upload_responses = upload_responses
        @grouping_strategy = if grouping_strategy == 'filename'
                               SdrClient::RedesignedClient::MatchingFileGroupingStrategy
                             else
                               SdrClient::RedesignedClient::SingleFileGroupingStrategy
                             end
        @file_set_strategy = if file_set_strategy == 'image'
                               SdrClient::RedesignedClient::ImageFileSetStrategy
                             else
                               SdrClient::RedesignedClient::FileTypeFileSetStrategy
                             end
      end

      def group
        request_builder
          .tap { |request| request.file_sets = build_filesets(uploads: upload_responses) }
          .to_cocina
      end

      private

      attr_reader :request_builder, :file_set_strategy, :grouping_strategy, :upload_responses

      # @param [Array<SdrClient::RedesignedClient::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<SdrClient::RedesignedClient::FileSet>] the uploads transformed to filesets
      def build_filesets(uploads:)
        grouping_strategy
          .run(uploads: uploads)
          .map
          .with_index(1) do |upload_group, i|
            SdrClient::RedesignedClient::FileSet.new(uploads: upload_group,
                                                     uploads_metadata: metadata_group(upload_group),
                                                     label: label(i),
                                                     type_strategy: file_set_strategy)
        end
      end

      def label(index)
        case request_builder.type
        when Cocina::Models::ObjectType.book
          "Page #{index}"
        else
          "Object #{index}"
        end
      end

      # Get the metadata for the files belonging to a fileset
      def metadata_group(upload_group)
        upload_group.each_with_object({}) do |upload, obj|
          obj[upload.filename] = request_builder.for(upload.filename)
        end
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  module Deposit
    # The process for doing a deposit
    class Process
      # @param [Request] metadata information about the object
      # @param [String] connection the server connection to use
      # @param [Boolean] accession should the accessionWF be started
      # @param [String] priority (nil) what processing priority should be used
      #                          either 'low' or 'default'
      # @param [Class] grouping_strategy class whose run method groups an array of uploads
      # @param [Class] file_set_type_strategy class whose run method determines file_set type
      # @param [Array<String>] files a list of relative filepaths to upload
      # @param [String] basepath filepath to which filepaths are relative
      # @param [Boolean] assign_doi should a DOI be assigned to this item
      # @param [Logger] logger the logger to use
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(metadata:,
                     connection:,
                     accession:,
                     basepath:,
                     priority: nil,
                     grouping_strategy: SingleFileGroupingStrategy,
                     file_set_type_strategy: FileTypeFileSetStrategy,
                     files: [],
                     assign_doi: false,
                     logger: Logger.new($stdout))
        @files = files
        @connection = connection
        @metadata = metadata
        @logger = logger
        @grouping_strategy = grouping_strategy
        @file_set_type_strategy = file_set_type_strategy
        @accession = accession
        @priority = priority
        @assign_doi = assign_doi
        @basepath = basepath
      end
      # rubocop:enable Metrics/ParameterLists

      # rubocop:disable Metrics/AbcSize
      # @return [String] job id for the background job result
      def run
        check_files_exist

        file_metadata = UploadFilesMetadataBuilder.build(files: files, mime_types: mime_types, basepath: basepath)
        upload_responses = UploadFiles.upload(file_metadata: file_metadata,
                                              filepath_map: filepath_map,
                                              logger: logger,
                                              connection: connection)
        metadata_builder = MetadataBuilder.new(metadata: metadata,
                                               grouping_strategy: grouping_strategy,
                                               file_set_type_strategy: file_set_type_strategy,
                                               logger: logger)
        request = metadata_builder.with_uploads(upload_responses)
        model = Cocina::Models.build_request(request.as_json.with_indifferent_access)
        CreateResource.run(accession: @accession,
                           priority: @priority,
                           assign_doi: @assign_doi,
                           metadata: model,
                           logger: logger,
                           connection: connection)
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :metadata, :files, :connection, :logger, :grouping_strategy, :file_set_type_strategy, :basepath

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |filepath|
          raise Errno::ENOENT, filepath unless ::File.exist?(absolute_filepath_for(filepath))
        end
      end

      def mime_types
        @mime_types ||=
          files.to_h do |filepath|
            [filepath, metadata.for(filepath)['mime_type']]
          end
      end

      def filepath_map
        @filepath_map ||= files.each_with_object({}) do |filepath, obj|
          obj[filepath] = absolute_filepath_for(filepath)
        end
      end

      def absolute_filepath_for(filepath)
        ::File.join(basepath, filepath)
      end
    end
  end
end

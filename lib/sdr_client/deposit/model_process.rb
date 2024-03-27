# frozen_string_literal: true

module SdrClient
  module Deposit
    # The process for doing a deposit from a Cocina Model
    class ModelProcess
      # @param [Cocina::Model::RequestDRO] request_dro for depositing
      # @param [Connection] connection the connection to use
      # @param [Boolean] accession should the accessionWF be started
      # @param [String] priority (nil) what processing priority should be used
      #                          either 'low' or 'default'
      # @param [Array<String>] files a list of relative filepaths to upload
      # @param [String] basepath filepath to which filepaths are relative
      # @param [Boolean] assign_doi should a DOI be assigned to this item
      # @param [Logger] logger the logger to use
      def initialize(request_dro:, # rubocop:disable Metrics/ParameterLists
                     connection:,
                     accession:,
                     basepath:,
                     priority: nil,
                     files: [],
                     assign_doi: false,
                     logger: Logger.new($stdout))
        @files = files
        @basepath = basepath
        @connection = connection
        @request_dro = request_dro
        @logger = logger
        @accession = accession
        @priority = priority
        @assign_doi = assign_doi
      end

      def run
        check_files_exist
        child_files_match

        # file_metadata is a map of relative filepaths to Files::DirectUploadRequests
        file_metadata = UploadFilesMetadataBuilder.build(files: files, mime_types: mime_types, basepath: basepath)
        # upload_response is an array of Files::DirectUploadResponse
        upload_responses = UploadFiles.upload(file_metadata: file_metadata,
                                              filepath_map: filepath_map,
                                              logger: logger,
                                              connection: connection)

        new_request_dro = UpdateDroWithFileIdentifiers.update(request_dro: request_dro, upload_responses: upload_responses)
        CreateResource.run(accession: @accession,
                           priority: @priority,
                           assign_doi: @assign_doi,
                           metadata: new_request_dro,
                           logger: logger,
                           connection: connection)
      end

      private

      attr_reader :request_dro, :files, :logger, :connection, :basepath

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |filepath|
          raise Errno::ENOENT, filepath unless ::File.exist?(absolute_filepath_for(filepath))
        end
      end

      def child_files_match
        # Files without request files.
        files.each do |filepath|
          raise "Request file not provided for #{filepath}" if request_files[filepath].nil?
        end

        # Request files without files
        request_files.each_key do |request_filename|
          raise "File not provided for request file #{request_filename}" unless files.include?(request_filename)
        end
      end

      # Map of relative filepaths to mimetypes
      def mime_types
        @mime_types ||=
          request_files.transform_values do |file|
            file.hasMimeType || 'application/octet-stream'
          end
      end

      # Map of absolute filepaths to Cocina::Models::RequestFiles
      def request_files
        @request_files ||= begin
          return {} unless request_dro.structural

          request_dro.structural.contains.map do |file_set|
            file_set.structural.contains.map do |file|
              [file.filename, file]
            end
          end.flatten(1).to_h
        end
      end

      def absolute_filepath_for(filename)
        ::File.join(basepath, filename)
      end

      def filepath_map
        @filepath_map ||= files.each_with_object({}) do |filepath, obj|
          obj[filepath] = absolute_filepath_for(filepath)
        end
      end
    end
  end
end

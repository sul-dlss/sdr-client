# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The process for doing a deposit from a Cocina Model
    class ModelProcess
      # @param [Cocina::Model::RequestDRO] request_dro for depositing
      # @param [Connection] connection the connection to use
      # @param [Array<String>] files a list of file names to upload
      # @param [Boolean] accession should the accessionWF be started
      # @param [Logger] logger the logger to use
      def initialize(request_dro:, connection:,
                     files: [], accession:, logger: Logger.new(STDOUT))
        @files = files
        @connection = connection
        @request_dro = request_dro
        @logger = logger
        @accession = accession
      end

      def run
        check_files_exist
        child_files_match

        file_metadata = UploadFilesMetadataBuilder.build(files: files, mime_types: mime_types)
        upload_responses = UploadFiles.upload(file_metadata: file_metadata,
                                              logger: logger,
                                              connection: connection)
        new_request_dro = UpdateDroWithFileIdentifiers.update(request_dro: request_dro, upload_responses: upload_responses)
        UploadResource.run(accession: @accession,
                           metadata: new_request_dro.to_json,
                           logger: logger,
                           connection: connection)
      end

      private

      attr_reader :request_dro, :files, :logger, :connection

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |file_name|
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
        end
      end

      def child_files_match
        # Files without request files.
        files.each do |filepath|
          filename = ::File.basename(filepath)

          raise "Request file not provided for #{filepath}" if request_files[filename].nil?
        end

        # Request files without files
        filenames = files.map { |filepath| ::File.basename(filepath) }
        request_files.keys.each do |request_filename|
          raise "File not provided for request file #{request_filename}" unless filenames.include?(request_filename)
        end
      end

      # Map of filenames to mimetypes
      def mime_types
        @mime_types ||=
          Hash[
            request_files.map do |filename, file|
              [filename, file.hasMimeType || 'application/octet-stream']
            end
          ]
      end

      # Map of filenames to request files
      def request_files
        @request_files ||= begin
          return {} unless request_dro.structural

          Hash[
              request_dro.structural.contains.map do |file_set|
                file_set.structural.contains.map do |file|
                  [file.filename, file]
                end
              end.flatten(1)
          ]
        end
      end
    end
  end
end

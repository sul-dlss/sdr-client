# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The file uploading part of a deposit
    class UploadFiles
      BLOB_PATH = '/v1/direct_uploads'
      # @param [Array<String>] files a list of file names to upload
      # @param [Logger] logger the logger to use
      def initialize(files:, logger:, connection:)
        @files = files
        @logger = logger
        @connection = connection
      end

      # @return [Array<SdrClient::Deposit::Files::DirectUploadResponse>] the responses from the server for the uploads
      def run
        file_metadata = collect_file_metadata
        upload_responses = upload_file_metadata(file_metadata)
        upload_files(upload_responses)
        upload_responses.values
      end

      private

      attr_reader :files, :logger, :connection

      def collect_file_metadata
        files.each_with_object({}) do |filename, obj|
          obj[filename] = Files::DirectUploadRequest.from_file(filename)
        end
      end

      # @param [Hash<String,Files::DirectUploadRequest>] file_metadata the filenames and their upload request
      def upload_file_metadata(file_metadata)
        Hash[file_metadata.map { |filename, metadata| [filename, direct_upload(metadata.to_json)] }]
      end

      def direct_upload(metadata_json)
        logger.info("Starting an upload request: #{metadata_json}")
        response = connection.post(BLOB_PATH, metadata_json, 'Content-Type' => 'application/json')
        raise "unexpected response: #{response.inspect}" unless response.status == 200

        logger.info("Response from server: #{response.body}")

        Files::DirectUploadResponse.new(JSON.parse(response.body))
      end

      # @param [Hash<String,Files::DirectUploadResponse>] upload_responses the filenames and their upload response
      def upload_files(upload_responses)
        upload_responses.each do |filename, response|
          upload_file(filename: filename,
                      url: response.direct_upload.fetch('url'),
                      content_type: response.content_type,
                      content_length: response.byte_size)

          logger.info('Upload complete')
        end
      end

      def upload_file(filename:, url:, content_type:, content_length:)
        logger.info("Uploading `#{filename}' to #{url}")

        upload_response = connection.put(url) do |req|
          req.body = ::File.open(filename)
          req.headers['Content-Type'] = content_type
          req.headers['Content-Length'] = content_length.to_s
        end

        raise "unexpected response: #{upload_response.inspect}" unless upload_response.status == 204
      end
    end
  end
end

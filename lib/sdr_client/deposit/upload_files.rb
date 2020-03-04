# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The file uploading part of a deposit
    class UploadFiles
      BLOB_PATH = '/v1/direct_uploads'
      # @param [Array<String>] files a list of file names to upload
      # @param [Logger] logger the logger to use
      # @param [Faraday::Connection] connection
      # @param [Request] metadata information about the object
      def initialize(files:, metadata:, logger:, connection:)
        @files = files
        @metadata = metadata
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

      attr_reader :files, :metadata, :logger, :connection

      def collect_file_metadata
        files.each_with_object({}) do |path, obj|
          file_name = ::File.basename(path)
          obj[path] = Files::DirectUploadRequest.from_file(path,
                                                           file_name: file_name,
                                                           content_type: metadata.for(file_name)['mime_type'])
        end
      end

      # @param [Hash<String,Files::DirectUploadRequest>] file_metadata the filenames and their upload request
      def upload_file_metadata(file_metadata)
        Hash[file_metadata.map { |filename, metadata| [filename, direct_upload(metadata.to_json)] }]
      end

      def direct_upload(metadata_json)
        logger.info("Starting an upload request: #{metadata_json}")
        response = connection.post(BLOB_PATH, metadata_json, 'Content-Type' => 'application/json')
        unexpected_response(response) unless response.status == 200

        logger.info("Response from server: #{response.body}")

        Files::DirectUploadResponse.new(JSON.parse(response.body))
      end

      def unexpected_response(response)
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.inspect}"
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

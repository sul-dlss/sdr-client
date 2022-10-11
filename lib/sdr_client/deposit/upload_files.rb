# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The file uploading part of a deposit
    class UploadFiles
      BLOB_PATH = '/v1/direct_uploads'

      # @param [Hash<String,Files::DirectUploadRequest>] the metadata for uploading the files
      # @param [Logger] logger the logger to use
      # @param [Connection] connection
      def self.upload(file_metadata:, logger:, connection:)
        new(file_metadata: file_metadata, logger: logger, connection: connection).run
      end

      # @param [Hash<String,Files::DirectUploadRequest>] the metadata for uploading the files
      # @param [Logger] logger the logger to use
      # @param [Connection] connection
      def initialize(file_metadata:, logger:, connection:)
        @file_metadata = file_metadata
        @logger = logger
        @connection = connection
      end

      # @return [Array<Files::DirectUploadResponse>] the responses from the server for the uploads
      def run
        file_metadata.map do |filename, metadata|
          direct_upload(metadata.to_json).tap do |response|
            # ActiveStorage modifies the filename provided in response, so setting here.
            response.filename = filename
            upload_file(filename: filename,
                        url: response.direct_upload.fetch('url'),
                        content_type: response.content_type,
                        content_length: response.byte_size)
            logger.info("Upload of #{filename} complete")
          end
        end
      end

      private

      attr_reader :logger, :connection, :file_metadata

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

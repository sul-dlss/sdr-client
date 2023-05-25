# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The file uploading part of a deposit
    class UploadFiles
      BLOB_PATH = '/v1/direct_uploads'

      # @param [Hash<String,Files::DirectUploadRequest>] file_metadata map of relative filepaths to file metadata
      # @param [Hash<String,String>] filepath_map map of relative filepaths to absolute filepaths
      # @param [Logger] logger the logger to use
      # @param [Connection] connection
      def self.upload(file_metadata:, filepath_map:, logger:, connection:)
        new(file_metadata: file_metadata, filepath_map: filepath_map, logger: logger, connection: connection).run
      end

      # @param [Hash<String,Files::DirectUploadRequest>] file_metadata map of relative filepaths to file metadata
      # @param [Hash<String,String>] filepath_map map of relative filepaths to absolute filepaths
      # @param [Logger] logger the logger to use
      # @param [Connection] connection
      def initialize(file_metadata:, filepath_map:, logger:, connection:)
        @file_metadata = file_metadata
        @filepath_map = filepath_map
        @logger = logger
        @connection = connection
      end

      # @return [Array<Files::DirectUploadResponse>] the responses from the server for the uploads
      def run # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        file_metadata.map do |filepath, metadata|
          log_message("metadata.to_json=#{metadata.to_json}", 'SdrClient::Deposit::UploadFiles#run file_metadata.map')
          direct_upload(metadata.to_json).tap do |response|
            log_message("response=#{response}", 'SdrClient::Deposit::UploadFiles#run direct_upload')
            log_message("response.content_type=#{response.content_type}", 'SdrClient::Deposit::UploadFiles#run direct_upload') # rubocop:disable Layout/LineLength
            # ActiveStorage modifies the filename provided in response, so setting here with the relative filename
            response.filename = filepath
            upload_file(filename: filepath,
                        url: response.direct_upload.fetch('url'),
                        content_type: response.content_type,
                        content_length: response.byte_size)
            logger.info("Upload of #{filepath} complete")
          end
        end
      end

      private

      attr_reader :logger, :connection, :file_metadata, :filepath_map

      def log_message(message, progname = nil, severity = Logger::Severity::INFO)
        logger = if defined?(::Rails) == 'constant'
                   ::Rails.logger
                 else
                   Logger.new($stdout)
                 end

        logger.log(severity, message, progname)
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

      def upload_file(filename:, url:, content_type:, content_length:)
        logger.info("Uploading `#{filename}' to #{url}")

        upload_response = connection.put(url) do |req|
          req.body = ::File.open(filepath_map[filename])
          req.headers['Content-Type'] = content_type
          req.headers['Content-Length'] = content_length.to_s
        end

        raise "unexpected response: #{upload_response.inspect}" unless upload_response.status == 204
      end
    end
  end
end

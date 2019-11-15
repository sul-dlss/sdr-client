# frozen_string_literal: true

require 'logger'

module RepositoryClient
  module Deposit
    # The process for doing a deposit
    class Process
      BLOB_PATH = '/rails/active_storage/direct_uploads'
      DRO_PATH = '/v1/resources'
      def initialize(label:, type:, url:, files: [], logger: Logger.new(STDOUT))
        @label = label
        @type = type
        @files = files
        @url = url
        @logger = logger
      end

      def run
        check_files_exist
        file_metadata = collect_file_metadata
        upload_responses = upload_file_metadata(file_metadata)
        upload_files(upload_responses)
        upload_metadata(upload_responses)
      end

      private

      attr_reader :label, :type, :files, :url, :logger

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |file_name|
          raise Errno::ENOENT, file_name unless File.exist?(file_name)
        end
      end

      def collect_file_metadata
        files.each_with_object({}) do |filename, obj|
          obj[filename] = Files::DirectUploadRequest.from_file(filename)
        end
      end

      # @param [Hash<String,Files::DirectUploadRequest>] file_metadata the filenames and their upload request
      def upload_file_metadata(file_metadata)
        Hash[file_metadata.map do |filename, metadata|
          logger.info("Starting an upload request: #{metadata.to_json}")
          response = Faraday.post(url + BLOB_PATH, metadata.to_json, 'Content-Type' => 'application/json')
          unless response.status == 200
            raise "unexpected response: #{response.inspect}"
          end

          logger.info("Response from server: #{response.body}")

          json = JSON.parse(response.body)
          [filename, Files::DirectUploadResponse.new(json)]
        end]
      end

      # @param [Hash<String,Files::DirectUploadResponse>] upload_responses the filenames and their upload response
      def upload_files(upload_responses)
        upload_responses.each do |filename, response|
          logger.info("Uploading: #{response.filename}")
          url = response.direct_upload.fetch('url')
          logger.info("url: #{url}")
          conn = Faraday.new(url) do |builder|
            builder.adapter :net_http
          end
          upload_response = conn.put(url) do |req|
            req.body = File.open(filename)
            req.headers['Content-Type'] = response.content_type
            req.headers['Content-Length'] = response.byte_size.to_s
          end

          unless upload_response.status == 204
            raise "unexpected response: #{upload_response.inspect}"
          end

          logger.info('Upload complete')
        end
      end

      def upload_metadata(upload_responses)
        metadata = Request.new(label: label,
                               type: type,
                               uploads: upload_responses.values)
        logger.info("Starting upload metadata: #{metadata.as_json}")
        request_json = JSON.generate(metadata.as_json)
        response = Faraday.post(url + DRO_PATH, request_json, 'Content-Type' => 'application/json')
        unless response.status == 200
          raise "unexpected response: #{response.inspect}"
        end

        logger.info("Response from server: #{response.body}")

        JSON.parse(response.body)
      end
    end
  end
end

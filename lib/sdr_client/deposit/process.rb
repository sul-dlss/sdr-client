# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The process for doing a deposit
    class Process
      BLOB_PATH = '/rails/active_storage/direct_uploads'
      DRO_PATH = '/v1/resources'
      def initialize(label: nil, type:, url:,
                     apo:, collection:, source_id:, catkey: nil,
                     files: [], logger: Logger.new(STDOUT))
        @label = label
        @type = type
        @files = files
        @url = url
        @apo = apo
        @collection = collection
        @source_id = source_id
        @catkey = catkey
        @logger = logger
      end

      def run
        check_files_exist
        file_metadata = collect_file_metadata
        upload_responses = upload_file_metadata(file_metadata)
        upload_files(upload_responses)
        metadata = Request.new(label: label,
                               type: type,
                               apo: apo,
                               collection: collection,
                               source_id: source_id,
                               catkey: catkey,
                               uploads: upload_responses.values)
        upload_metadata(metadata.as_json)
      end

      private

      attr_reader :label, :type, :apo, :collection, :source_id, :catkey, :files, :url, :logger

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
        Hash[file_metadata.map { |filename, metadata| [filename, direct_upload(metadata.to_json)] }]
      end

      def direct_upload(metadata_json)
        logger.info("Starting an upload request: #{metadata_json}")
        response = Faraday.post(url + BLOB_PATH, metadata_json, 'Content-Type' => 'application/json')
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
        conn = Faraday.new(url) do |builder|
          builder.adapter :net_http
        end
        upload_response = conn.put(url) do |req|
          req.body = File.open(filename)
          req.headers['Content-Type'] = content_type
          req.headers['Content-Length'] = content_length.to_s
        end

        raise "unexpected response: #{upload_response.inspect}" unless upload_response.status == 204
      end

      def upload_metadata(metadata)
        logger.info("Starting upload metadata: #{metadata}")
        request_json = JSON.generate(metadata)
        response = Faraday.post(url + DRO_PATH, request_json, 'Content-Type' => 'application/json')
        unexpected_response(response) unless response.status == 200

        logger.info("Response from server: #{response.body}")

        JSON.parse(response.body)
      end

      def unexpected_response(response)
        raise "unexpected response: #{response.inspect}" unless response.status == 400

        puts "\nThere was an error with your request: #{response.body}"
        exit(1)
      end
    end
  end
end

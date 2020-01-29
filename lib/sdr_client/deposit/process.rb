# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The process for doing a deposit
    class Process
      BLOB_PATH = '/v1/direct_uploads'
      DRO_PATH = '/v1/resources'
      # @param [Request] metadata information about the object
      # @param [Class] grouping_strategy class whose run method groups an array of uploads
      # @param [String] url the server to send to
      # @param [String] token the bearer auth token for the server
      # @param [Array<String>] files a list of file names to upload
      # @param [Hash<String, Hash<String, String>>] files_metadata file name, hash of additional file metadata
      # Additional metadata includes access, preserve, shelve, md5, sha1
      # @param [Logger] logger the logger to use
      # rubocop:disable Metrics/ParameterLists
      def initialize(metadata:, grouping_strategy: SingleFileGroupingStrategy, url:,
                     token:, files: [], files_metadata: {}, logger: Logger.new(STDOUT))
        @files = files
        @url = url
        @token = token
        @metadata = metadata
        @logger = logger
        @grouping_strategy = grouping_strategy
        @files_metadata = files_metadata
      end
      # rubocop:enable Metrics/ParameterLists

      def run
        check_files_exist
        file_metadata = collect_file_metadata
        upload_responses = upload_file_metadata(file_metadata)
        upload_files(upload_responses)
        file_sets = build_filesets(uploads: upload_responses.values, files_metadata: files_metadata)
        request = metadata.with_file_sets(file_sets)
        upload_metadata(request.as_json)
      end

      private

      attr_reader :metadata, :files, :url, :token, :logger, :grouping_strategy, :files_metadata

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |file_name|
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
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

      # @return [Hash<Symbol,String>] the result of the metadata call
      def upload_metadata(metadata)
        logger.info("Starting upload metadata: #{metadata}")
        request_json = JSON.generate(metadata)
        response = connection.post(DRO_PATH, request_json, 'Content-Type' => 'application/json')
        unexpected_response(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        { druid: JSON.parse(response.body)['druid'], background_job: response.headers['Location'] }
      end

      def unexpected_response(response)
        raise "unexpected response: #{response.inspect}" unless response.status == 400

        puts "\nThere was an error with your request: #{response.body}"
        exit(1)
      end

      def connection
        @connection ||= Faraday.new(url: url) do |conn|
          conn.authorization :Bearer, token
          conn.adapter :net_http
        end
      end

      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @param [Hash<String,Hash<String, String>>] files_metadata filename, hash of additional file metadata.
      # @return [Array<SdrClient::Deposit::FileSet>] the uploads transformed to filesets
      def build_filesets(uploads:, files_metadata:)
        grouped_uploads = grouping_strategy.run(uploads: uploads)
        grouped_uploads.each_with_index.map do |upload_group, i|
          metadata_group = {}
          upload_group.each { |upload| metadata_group[upload.filename] = files_metadata.fetch(upload.filename, {}) }
          FileSet.new(uploads: upload_group, uploads_metadata: metadata_group, label: "Object #{i + 1}")
        end
      end
    end
  end
end

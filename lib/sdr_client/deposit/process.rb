# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The process for doing a deposit
    class Process
      DRO_PATH = '/v1/resources'
      # @param [Request] metadata information about the object
      # @param [Class] grouping_strategy class whose run method groups an array of uploads
      # @param [String] url the server to send to
      # @param [String] token the bearer auth token for the server
      # @param [Array<String>] files a list of file names to upload
      # @param [Logger] logger the logger to use
      # rubocop:disable Metrics/ParameterLists
      def initialize(metadata:, grouping_strategy: SingleFileGroupingStrategy, url:,
                     token:, files: [], logger: Logger.new(STDOUT))
        @files = files
        @url = url
        @token = token
        @metadata = metadata
        @logger = logger
        @grouping_strategy = grouping_strategy
      end
      # rubocop:enable Metrics/ParameterLists

      def run
        check_files_exist
        upload_responses = UploadFiles.new(files: files,
                                           logger: logger,
                                           connection: connection,
                                           metadata: metadata).run
        metadata_builder = MetadataBuilder.new(metadata: metadata,
                                               grouping_strategy: grouping_strategy,
                                               logger: logger)
        request = metadata_builder.with_uploads(upload_responses)
        upload_metadata(request.as_json)
      end

      private

      attr_reader :metadata, :files, :url, :token, :logger, :grouping_strategy

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |file_name|
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
        end
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
        raise "There was an error with your request: #{response.body}" if response.status == 400
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.inspect}"
      end

      def connection
        @connection ||= Faraday.new(url: url) do |conn|
          conn.authorization :Bearer, token
          conn.adapter :net_http
        end
      end
    end
  end
end

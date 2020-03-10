# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The process for doing a deposit from a Cocina Model
    class ModelProcess
      DRO_PATH = '/v1/resources'
      # @param [Cocina::Model::RequestDRO] request_dro for depositing
      # @param [String] url the server to send to
      # @param [String] token the bearer auth token for the server
      # @param [Array<String>] files a list of file names to upload
      # @param [Logger] logger the logger to use
      def initialize(request_dro:, url:,
                     token:, files: [], logger: Logger.new(STDOUT))
        @files = files
        @url = url
        @token = token
        @request_dro = request_dro
        @logger = logger
      end

      def run
        check_files_exist
        UploadFiles.new(files: files,
                        logger: logger,
                        connection: connection,
                        mime_types: mime_types).run
        upload_request_dro
      end

      private

      attr_reader :request_dro, :files, :url, :token, :logger

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |file_name|
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
        end
      end

      # @return [Hash<Symbol,String>] the result of the metadata call
      # rubocop:disable Metrics/AbcSize
      def upload_request_dro
        request_json = request_dro.to_json
        logger.info("Starting upload metadata: #{request_json}")
        response = connection.post(DRO_PATH, request_json, 'Content-Type' => 'application/json')
        unexpected_response(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        { druid: JSON.parse(response.body)['druid'], background_job: response.headers['Location'] }
      end
      # rubocop:enable Metrics/AbcSize

      def unexpected_response(response)
        raise "There was an error with your request: #{response.body}" if response.status == 400
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.status} #{response.body}"
      end

      def connection
        @connection ||= Faraday.new(url: url) do |conn|
          conn.authorization :Bearer, token
          conn.adapter :net_http
        end
      end

      def mime_types
        @mime_types ||=
          Hash[
            request_dro.structural.contains.map do |file_set|
              file_set.structural.contains.map do |file|
                [file.filename, file.hasMimeType || 'application/octet-stream']
              end
            end.flatten(1)
          ]
      end
    end
  end
end

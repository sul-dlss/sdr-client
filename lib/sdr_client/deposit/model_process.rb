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
        child_files_match

        upload_responses = UploadFiles.new(files: files,
                                           logger: logger,
                                           connection: connection,
                                           mime_types: mime_types).run
        new_request_dro = with_external_identifiers(upload_responses)
        upload_request_dro(new_request_dro.to_json)
      end

      private

      attr_reader :request_dro, :files, :url, :token, :logger

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

      # @return [Hash<Symbol,String>] the result of the metadata call
      def upload_request_dro(request_json)
        logger.info("Starting upload metadata: #{request_json}")
        response = connection.post(DRO_PATH, request_json, 'Content-Type' => 'application/json')
        unexpected_response(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        { druid: JSON.parse(response.body)['druid'], background_job: response.headers['Location'] }
      end

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
        @request_files ||=
          Hash[
              request_dro.structural.contains.map do |file_set|
                file_set.structural.contains.map do |file|
                  [file.filename, file]
                end
              end.flatten(1)
          ]
      end

      def with_external_identifiers(upload_responses)
        signed_id_map = Hash[upload_responses.map { |response| [response.filename, response.signed_id] }]

        # Manipulating request_dro as hash since immutable
        request_dro_hash = request_dro.to_h
        request_dro_hash[:structural][:contains].each do |file_set|
          file_set[:structural][:contains].each do |file|
            file[:externalIdentifier] = signed_id_map[file[:filename]]
          end
        end

        Cocina::Models::RequestDRO.new(request_dro_hash)
      end
    end
  end
end

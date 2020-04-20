# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # The process for doing a deposit
    class Process
      DRO_PATH = '/v1/resources'
      # @param [Request] metadata information about the object
      # @param [Class] grouping_strategy class whose run method groups an array of uploads
      # @param [String] connection the server connection to use
      # @param [Array<String>] files a list of file names to upload
      # @param [Boolean] accession should the accessionWF be started
      # @param [Logger] logger the logger to use
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(metadata:, grouping_strategy: SingleFileGroupingStrategy,
                     connection:, files: [], accession:, logger: Logger.new(STDOUT))
        @files = files
        @connection = connection
        @metadata = metadata
        @logger = logger
        @grouping_strategy = grouping_strategy
        @accession = accession
      end
      # rubocop:enable Metrics/ParameterLists

      # rubocop:disable Metrics/AbcSize
      def run
        check_files_exist
        upload_responses = UploadFiles.new(files: files,
                                           logger: logger,
                                           connection: connection,
                                           mime_types: mime_types).run
        metadata_builder = MetadataBuilder.new(metadata: metadata,
                                               grouping_strategy: grouping_strategy,
                                               logger: logger)
        request = metadata_builder.with_uploads(upload_responses)
        model = Cocina::Models.build_request(request.as_json.with_indifferent_access)
        upload_metadata(model.to_h)
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :metadata, :files, :connection, :logger, :grouping_strategy

      def check_files_exist
        logger.info('checking to see if files exist')
        files.each do |file_name|
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
        end
      end

      def accession?
        @accession
      end

      # @param [Hash<Symbol,String>] the result of the metadata call
      # @param [Boolean] accession should the accessionWF be started
      # @return [Hash<Symbol,String>] the result of the metadata call
      def upload_metadata(metadata)
        response = metadata_request(metadata)
        unexpected_response(response) unless response.status == 201

        logger.info("Response from server: #{response.body}")

        { druid: JSON.parse(response.body)['druid'], background_job: response.headers['Location'] }
      end

      def metadata_request(metadata)
        logger.debug("Starting upload metadata: #{metadata}")

        connection.post(path, JSON.generate(metadata), 'Content-Type' => 'application/json')
      end

      def path
        path = DRO_PATH
        path += '?accession=true' if accession?
        path
      end

      def unexpected_response(response)
        raise "There was an error with your request: #{response.body}" if response.status == 400
        raise 'There was an error with your credentials. Perhaps they have expired?' if response.status == 401

        raise "unexpected response: #{response.status} #{response.body}"
      end

      def mime_types
        @mime_types ||=
          Hash[
            files.map do |filepath|
              filename = ::File.basename(filepath)
              [filename, metadata.for(filename)['mime_type']]
            end
          ]
      end
    end
  end
end

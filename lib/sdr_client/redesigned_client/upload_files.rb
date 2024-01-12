# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # The file uploading part of a deposit
    class UploadFiles
      # @param [Hash<String,DirectUploadRequest>] file_metadata map of relative filepaths to file metadata
      # @param [Hash<String,String>] filepath_map map of relative filepaths to absolute filepaths
      def self.upload(file_metadata:, filepath_map:)
        new(file_metadata: file_metadata, filepath_map: filepath_map).upload
      end

      # @param [Hash<String,DirectUploadRequest>] file_metadata map of relative filepaths to file metadata
      # @param [Hash<String,String>] filepath_map map of relative filepaths to absolute filepaths
      def initialize(file_metadata:, filepath_map:)
        @file_metadata = file_metadata
        @filepath_map = filepath_map
      end

      # @return [Array<DirectUploadResponse>] the responses from the server for the uploads
      def upload
        file_metadata.map do |filepath, metadata|
          direct_upload(metadata.to_json).tap do |response|
            # ActiveStorage modifies the filename provided in response, so setting here with the relative filename
            response.filename = filepath
            upload_file(response)
            logger.info("Upload of #{filepath} complete")
          end
        end
      end

      private

      attr_reader :file_metadata, :filepath_map

      def logger
        SdrClient::RedesignedClient.config.logger
      end

      def client
        SdrClient::RedesignedClient.instance
      end

      def path
        '/v1/direct_uploads'
      end

      def direct_upload(metadata_json)
        logger.info("Starting an upload request: #{metadata_json}")
        response = client.post(path: path, body: metadata_json)

        logger.info("Response from server: #{response}")
        DirectUploadResponse.new(response)
      end

      def upload_file(response)
        logger.info("Uploading `#{response.filename}' to #{response.direct_upload.fetch('url')}")

        client.put(
          path: response.direct_upload.fetch('url'),
          body: ::File.open(filepath_map[response.filename]),
          headers: {
            'content-type' => response.content_type,
            'content-length' => response.byte_size.to_s
          },
          expected_status: 204
        )
      end
    end
  end
end

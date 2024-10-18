# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # The file uploading part of a deposit for a single file or IO
    class UploadFile
      # @param [Files::DirectUploadRequest>] direct_upload_request file metadata
      # @param [String|IO] filepath_or_io the file or IO to upload
      def self.upload(direct_upload_request:, filepath_or_io:)
        new(direct_upload_request: direct_upload_request, filepath_or_io: filepath_or_io).upload
      end

      # @param [Files::DirectUploadRequest>] direct_upload_request file metadata
      # @param [String|IO] filepath_or_io the file or IO to upload
      def initialize(direct_upload_request:, filepath_or_io:)
        @direct_upload_request = direct_upload_request
        @filepath_or_io = filepath_or_io
      end

      # @return [<DirectUploadResponse] the responses from the server for the uploads
      def upload
        direct_upload.tap do |response|
          # ActiveStorage modifies the filename provided in response, so setting here with the relative filename
          response.filename = direct_upload_request.filename
          upload_file(response)
          logger.info("Upload of #{direct_upload_request.filename} complete")
        end
      end

      private

      attr_reader :direct_upload_request, :filepath_or_io

      def logger
        SdrClient::RedesignedClient.config.logger
      end

      def client
        SdrClient::RedesignedClient.instance
      end

      def path
        '/v1/direct_uploads'
      end

      def direct_upload
        metadata_json = direct_upload_request.to_json
        logger.info("Starting an upload request: #{metadata_json}")
        response = client.post(path: path, body: metadata_json)

        logger.info("Response from server: #{response}")
        DirectUploadResponse.new(response)
      end

      def upload_file(response)
        logger.info("Uploading `#{response.filename}' to #{response.direct_upload.fetch('url')}")

        client.put(
          path: response.direct_upload.fetch('url'),
          body: body,
          headers: {
            'content-type' => response.content_type,
            'content-length' => response.byte_size.to_s
          },
          expected_status: 204
        )
      end

      def body
        if filepath_or_io.is_a?(String)
          ::File.open(filepath_or_io)
        else
          filepath_or_io
        end
      end
    end
  end
end

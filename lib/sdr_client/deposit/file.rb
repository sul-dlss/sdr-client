# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the File metadata that we send to the server for doing a deposit
    class File
      # rubocop:disable Metrics/ParameterLists
      def initialize(external_identifier:, label:, filename:,
                     view: 'dark', download: 'none', location: nil, preserve: true, shelve: true,
                     publish: true, mime_type: nil, md5: nil, sha1: nil,
                     use: nil)
        @external_identifier = external_identifier
        @label = label
        @filename = filename
        @view = view
        @download = download
        @location = location
        @preserve = preserve
        @shelve = view == 'dark' ? false : shelve
        @publish = publish
        @mime_type = mime_type
        @md5 = md5
        @sha1 = sha1
        @use = use
      end
      # rubocop:enable Metrics/ParameterLists

      def as_json
        {
          type: Cocina::Models::ObjectType.file,
          label: @label,
          filename: @filename,
          externalIdentifier: @external_identifier,
          access: {
            view: @view,
            download: @download
          },
          administrative: {
            sdrPreserve: @preserve,
            shelve: @shelve,
            publish: @publish
          },
          version: 1,
          hasMessageDigests: message_digests
        }.tap do |json|
          json['hasMimeType'] = @mime_type if @mime_type
          json['use'] = @use if @use
          json[:access][:location] = @location if @location
        end
      end

      private

      def message_digests
        @message_digests ||= [].tap do |message_digests|
          message_digests << create_message_digest('md5', @md5) unless @md5.nil?
          message_digests << create_message_digest('sha1', @sha1) unless @sha1.nil?
        end
      end

      def create_message_digest(algorithm, digest)
        {
          type: algorithm,
          digest: digest
        }
      end
    end
  end
end

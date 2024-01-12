# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # This represents the File metadata that we send to the server for doing a deposit
    class File
      # @param [String] external_identifier used for object IDs (e.g., druids)
      # @param [String] label the required object label
      # @param [String] filename a filename
      # @param [Hash] options optional parameters
      # @option options [String] view the access level for viewing the object
      # @option options [String] download the access level for downloading the object
      # @option options [Boolean] preserve whether to preserve the file or not
      # @option options [Boolean] shelve whether to shelve the file or not
      # @option options [Boolean] publish whether to publish the file or not
      # @option options [String] mime_type the MIME type of the file
      # @option options [String] md5 the MD5 digest of the file
      # @option options [String] sha1 the SHA1 digest of the file
      # @option options [String] use the use and reproduction statement
      def initialize(external_identifier:, label:, filename:, **options)
        @external_identifier = external_identifier
        @label = label
        @filename = filename
        @options = options
      end

      def to_h # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        {
          type: Cocina::Models::ObjectType.file,
          label: label,
          filename: filename,
          externalIdentifier: external_identifier,
          access: {
            view: view,
            download: download
          },
          administrative: {
            sdrPreserve: preserve,
            shelve: shelve,
            publish: publish
          },
          version: 1,
          hasMessageDigests: message_digests
        }.tap do |json|
          json['hasMimeType'] = mime_type if mime_type
          json['use'] = use if use
        end
      end

      private

      attr_reader :external_identifier, :label, :filename, :options

      def message_digests
        [].tap do |message_digests|
          message_digests << { type: 'md5', digest: md5 } if md5
          message_digests << { type: 'sha1', digest: sha1 } if sha1
        end
      end

      def view
        options.fetch(:view, 'dark')
      end

      def download
        options.fetch(:download, 'none')
      end

      def preserve
        options.fetch(:preserve, true)
      end

      def shelve
        return false if view == 'dark'

        options.fetch(:shelve, true)
      end

      def publish
        options.fetch(:publish, true)
      end

      def mime_type
        options[:mime_type]
      end

      def md5
        options[:md5]
      end

      def sha1
        options[:sha1]
      end

      def use
        options[:use]
      end
    end
  end
end

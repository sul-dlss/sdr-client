# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the File metadata that we send to the server for doing a deposit
    class File
      # rubocop:disable Metrics/ParameterLists
      def initialize(external_identifier:, label:, filename:,
                     access: 'dark', preserve: false, shelve: false,
                     md5: nil, sha1: nil)
        @external_identifier = external_identifier
        @label = label
        @filename = filename
        @access = access
        @preserve = preserve
        @shelve = shelve
        @md5 = md5
        @sha1 = sha1
      end
      # rubocop:enable Metrics/ParameterLists

      # rubocop:disable Metrics/MethodLength
      def as_json
        {
          "type": 'http://cocina.sul.stanford.edu/models/file.jsonld',
          label: @label,
          filename: @filename,
          externalIdentifier: @external_identifier,
          access: {
            access: @access
          },
          administrative: {
            sdrPreserve: @preserve,
            shelve: @shelve
          }
        }.tap do |json|
          json['hasMessageDigests'] = message_digests unless message_digests.empty?
        end
      end
      # rubocop:enable Metrics/MethodLength

      private

      def message_digests
        @message_digests ||= [].tap do |message_digests|
          message_digests << create_message_digest('md5', @md5) unless @md5.nil?
          message_digests << create_message_digest('sha1', @sha1) unless @sha1.nil?
        end
      end

      def create_message_digest(algorithm, digest)
        {
          "type": algorithm,
          digest: digest
        }
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the metadata that we send to the server for doing a deposit
    class Request
      # @param [String] label the required object label
      # @param [Time|nil] embargo_release_date when the item should be released from embargo or nil if no embargo
      # @param [String] type (http://cocina.sul.stanford.edu/models/object.jsonld) the required object type.
      # @param [Array<FileSet>] file_sets the file sets to attach.
      # @param [Hash<String, Hash<String, String>>] files_metadata file name, hash of additional file metadata
      # Additional metadata includes access, preserve, shelve, md5, sha1
      # rubocop:disable Metrics/ParameterLists
      def initialize(label: nil,
                     apo:,
                     collection:,
                     source_id:,
                     catkey: nil,
                     embargo_release_date: nil,
                     type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
                     file_sets: [],
                     files_metadata: {})
        @label = label
        @type = type
        @source_id = source_id
        @collection = collection
        @catkey = catkey
        @embargo_release_date = embargo_release_date
        @apo = apo
        @file_sets = file_sets
        @files_metadata = files_metadata
      end
      # rubocop:enable Metrics/ParameterLists

      def as_json
        {
          access: access,
          type: type,
          administrative: administrative,
          identification: identification,
          structural: structural
        }.tap do |json|
          json[:label] = label if label
        end
      end

      # @return [Request] a clone of this request with the file_sets added
      def with_file_sets(file_sets)
        Request.new(label: label,
                    apo: apo,
                    collection: collection,
                    source_id: source_id,
                    catkey: catkey,
                    embargo_release_date: embargo_release_date,
                    type: type,
                    file_sets: file_sets,
                    files_metadata: files_metadata)
      end

      # @param [String] filename
      # @return [Hash] the metadata for the file
      def for(filename)
        files_metadata.fetch(filename, {})
      end

      private

      attr_reader :label, :file_sets, :source_id, :catkey, :apo, :collection,
                  :type, :files_metadata, :embargo_release_date

      def administrative
        {
          hasAdminPolicy: apo
        }
      end

      def identification
        { sourceId: source_id }.tap do |json|
          json[:catkey] = catkey if catkey
        end
      end

      def structural
        {
          isMemberOf: collection,
          contains: file_sets.map(&:as_json)
        }
      end

      def access
        {}.tap do |json|
          json[:embargoReleaseDate] = embargo_release_date.strftime('%FT%T%:z') if embargo_release_date
        end
      end
    end
  end
end

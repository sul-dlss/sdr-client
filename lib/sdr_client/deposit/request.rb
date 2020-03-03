# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the metadata that we send to the server for doing a deposit
    class Request
      # @param [String] label the required object label
      # @param [Time|nil] embargo_release_date when the item should be released from embargo or nil if no embargo
      # @param [String] embargo_access access after embargo has expired if embargoed
      # @param [String] type (http://cocina.sul.stanford.edu/models/object.jsonld) the required object type.
      # @param [Array<FileSet>] file_sets the file sets to attach.
      # @param [Hash<String, Hash<String, String>>] files_metadata file name, hash of additional file metadata
      # Additional metadata includes access, preserve, shelve, md5, sha1
      # rubocop:disable Metrics/ParameterLists
      def initialize(label: nil,
                     access: 'dark',
                     use_statement: nil,
                     copyright: nil,
                     apo:,
                     collection: nil,
                     source_id:,
                     catkey: nil,
                     embargo_release_date: nil,
                     embargo_access: 'world',
                     type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
                     viewing_direction: nil,
                     file_sets: [],
                     files_metadata: {})
        @label = label
        @type = type
        @source_id = source_id
        @collection = collection
        @catkey = catkey
        @embargo_release_date = embargo_release_date
        @embargo_access = embargo_access
        @access = access
        @use_statement = use_statement
        @copyright = copyright
        @apo = apo
        @file_sets = file_sets
        @files_metadata = files_metadata
        @viewing_direction = viewing_direction
      end
      # rubocop:enable Metrics/ParameterLists

      def as_json
        {
          access: access_struct,
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
                    access: access,
                    apo: apo,
                    collection: collection,
                    copyright: copyright,
                    source_id: source_id,
                    catkey: catkey,
                    embargo_release_date: embargo_release_date,
                    embargo_access: embargo_access,
                    type: type,
                    use_statement: use_statement,
                    viewing_direction: viewing_direction,
                    file_sets: file_sets,
                    files_metadata: files_metadata)
      end

      # @param [String] filename
      # @return [Hash] the metadata for the file
      def for(filename)
        files_metadata.fetch(filename, {})
      end

      private

      attr_reader :access, :label, :file_sets, :source_id, :catkey, :apo, :collection,
                  :type, :files_metadata, :embargo_release_date, :embargo_access,
                  :viewing_direction, :use_statement, :copyright

      def administrative
        {
          hasAdminPolicy: apo
        }
      end

      def identification
        { sourceId: source_id }.tap do |json|
          json[:catalogLinks] = [{ catalog: 'symphony', catalogRecordId: catkey }] if catkey
        end
      end

      def structural
        {}.tap do |json|
          json[:isMemberOf] = collection if collection
          json[:contains] = file_sets.map(&:as_json) unless file_sets.empty?
          json[:hasMemberOrders] = [{ viewingDirection: viewing_direction }] if viewing_direction
        end
      end

      def access_struct
        { access: access }.tap do |json|
          json[:useAndReproductionStatement] = use_statement if use_statement
          json[:copyright] = copyright if copyright

          if embargo_release_date
            json[:embargo] = {
              releaseDate: embargo_release_date.strftime('%FT%T%:z'),
              access: embargo_access
            }
          end
        end
      end
    end
  end
end

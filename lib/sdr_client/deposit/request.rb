# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the metadata that we send to the server for doing a deposit
    class Request
      # @param [String] label the required object label
      # @param [Time|nil] embargo_release_date when the item should be released from embargo or nil if no embargo
      # @param [String] embargo_access access after embargo has expired if embargoed
      # @param [String] type (https://cocina.sul.stanford.edu/models/object) the required object type.
      # @param [Array<FileSet>] file_sets the file sets to attach.
      # @param [Hash<String, Hash<String, String>>] files_metadata file name, hash of additional file metadata
      # Additional metadata includes access, preserve, shelve, publish, md5, sha1
      # rubocop:disable Metrics/ParameterLists
      def initialize(label: nil,
                     view: 'dark',
                     download: 'none',
                     location: nil,
                     use_and_reproduction: nil,
                     copyright: nil,
                     apo:,
                     collection: nil,
                     source_id:,
                     catkey: nil,
                     folio_instance_hrid: nil,
                     embargo_release_date: nil,
                     embargo_access: 'world',
                     embargo_download: 'world',
                     type: Cocina::Models::ObjectType.object,
                     viewing_direction: nil,
                     file_sets: [],
                     files_metadata: {})
        @label = label
        @type = type
        @source_id = source_id
        @collection = collection
        @catkey = catkey
        @folio_instance_hrid = folio_instance_hrid
        @embargo_release_date = embargo_release_date
        @embargo_access = embargo_access
        @embargo_download = embargo_download
        @view = view
        @download = download
        @location = location
        @use_and_reproduction = use_and_reproduction
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
          structural: structural,
          version: 1,
          label: label.nil? ? ':auto' : label
        }
      end

      # @return [Request] a clone of this request with the file_sets added
      def with_file_sets(file_sets)
        Request.new(label: label,
                    view: view,
                    download: download,
                    location: location,
                    apo: apo,
                    collection: collection,
                    copyright: copyright,
                    source_id: source_id,
                    catkey: catkey,
                    folio_instance_hrid: folio_instance_hrid,
                    embargo_release_date: embargo_release_date,
                    embargo_access: embargo_access,
                    embargo_download: embargo_download,
                    type: type,
                    use_and_reproduction: use_and_reproduction,
                    viewing_direction: viewing_direction,
                    file_sets: file_sets,
                    files_metadata: files_metadata)
      end

      # @param [String] filename
      # @return [Hash] the metadata for the file
      def for(filename)
        metadata = files_metadata.fetch(filename, {}).with_indifferent_access
        metadata[:view] = view unless metadata.key?(:view)
        metadata[:download] = download unless metadata.key?(:download)
        metadata[:location] = location unless metadata.key?(:location)
        metadata
      end

      attr_reader :type

      private

      attr_reader :view, :label, :file_sets, :source_id, :catkey, :folio_instance_hrid, :apo, :collection,
                  :files_metadata, :embargo_release_date, :embargo_access, :embargo_download,
                  :viewing_direction, :use_and_reproduction, :copyright, :download, :location

      def administrative
        {
          hasAdminPolicy: apo
        }
      end

      def identification
        { sourceId: source_id }.tap do |json|
          json[:catalogLinks] = []
          json[:catalogLinks] << { catalog: 'symphony', catalogRecordId: catkey, refresh: true } if catkey
          if folio_instance_hrid
            json[:catalogLinks] << { catalog: 'folio', catalogRecordId: folio_instance_hrid,
                                     refresh: true }
          end
          json.delete(:catalogLinks) if json[:catalogLinks].empty?
        end
      end

      def structural
        {}.tap do |json|
          json[:isMemberOf] = [collection] if collection
          json[:contains] = file_sets.map(&:as_json) unless file_sets.empty?
          json[:hasMemberOrders] = [{ viewingDirection: viewing_direction }] if viewing_direction
        end
      end

      def access_struct
        {
          view: view,
          download: download
        }.tap do |json|
          json[:useAndReproductionStatement] = use_and_reproduction if use_and_reproduction
          json[:copyright] = copyright if copyright
          json[:location] = location if location

          if embargo_release_date
            json[:embargo] = {
              releaseDate: embargo_release_date.strftime('%FT%T%:z'),
              view: embargo_access,
              download: embargo_download
            }
          end
        end
      end
    end
  end
end

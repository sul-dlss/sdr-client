# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Builds a Cocina request object from metadata. This is what we send to the server when doing a deposit.
    class RequestBuilder # rubocop:disable Metrics/ClassLength
      # @param [String] apo the object ID of the administrative policy object
      # @param [String] source_id the source ID of the object
      # @param [Hash] options optional parameters
      # @option options [String] label the required object label
      # @option options [String] view the access level for viewing the object
      # @option options [String] download the access level for downloading the object
      # @option options [String] location the location for location-based access
      # @option options [String] type (https://cocina.sul.stanford.edu/models/object) the required object type.
      # @option options [String] use_and_reproduction the use and reproduction statement
      # @option options [String] copyright the copyright statement
      # @option options [String] collection the object ID of the collection object
      # @option options [String] catkey the catalog key (from now unused Symphony ILS)
      # @option options [String] folio_instance_hrid the instance ID from the Folio ILS
      # @option options [String] viewing_direction the viewing direction (left to right, right to left)
      # @option options [Date|nil] embargo_release_date when to release the embargo (or nil if none)
      # @option options [String] embargo_access the access level for viewing the object after the embargo period
      # @option options [String] embargo_download the access level for downloading the object after the embargo period
      # @option options [Array<FileSet>] file_sets the file sets to attach.
      # @option options [Hash<String, Hash<String, String>>] files_metadata file name, hash of additional file metadata
      # Additional metadata includes access, preserve, shelve, publish, md5, sha1
      def initialize(apo:, source_id:, **options)
        @apo = apo
        @source_id = source_id
        @options = options
      end

      def to_h
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

      def to_cocina
        Cocina::Models.build_request(to_h.with_indifferent_access)
      end

      # @param [String] filename
      # @return [Hash] the metadata for the file
      def for(filename)
        files_metadata
          .fetch(filename, {})
          .with_indifferent_access
          .tap do |metadata|
            metadata[:view] = view unless metadata.key?(:view)
            metadata[:download] = download unless metadata.key?(:download)
        end
      end

      def type
        options.fetch(:type, Cocina::Models::ObjectType.object)
      end

      attr_writer :file_sets

      private

      attr_reader :apo, :source_id, :options

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
          json[:contains] = file_sets.map(&:to_h) unless file_sets.empty?
          json[:hasMemberOrders] = [{ viewingDirection: viewing_direction }] if viewing_direction
        end
      end

      def access_struct # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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

      def view
        options.fetch(:view, 'dark')
      end

      def download
        options.fetch(:download, 'none')
      end

      def location
        options[:location]
      end

      def label
        options[:label]
      end

      def use_and_reproduction
        options[:use_and_reproduction]
      end

      def copyright
        options[:copyright]
      end

      def collection
        options[:collection]
      end

      def catkey
        options[:catkey]
      end

      def folio_instance_hrid
        options[:folio_instance_hrid]
      end

      def viewing_direction
        options[:viewing_direction]
      end

      def embargo_release_date
        options[:embargo_release_date]
      end

      def embargo_access
        options.fetch(:embargo_access, 'world')
      end

      def embargo_download
        options.fetch(:embargo_download, 'world')
      end

      def file_sets
        @file_sets ||= options.fetch(:file_sets, [])
      end

      def files_metadata
        options.fetch(:files_metadata, {})
      end
    end
  end
end

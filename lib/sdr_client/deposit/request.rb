# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the metadata that we send to the server for doing a deposit
    class Request
      # @param [String] label the required object label
      # @param [String] type (http://cocina.sul.stanford.edu/models/object.jsonld) the required object type.
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      def initialize(label: nil,
                     apo:,
                     collection:,
                     source_id:,
                     catkey: nil,
                     type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
                     uploads: [])
        @label = label
        @type = type
        @source_id = source_id
        @collection = collection
        @catkey = catkey
        @apo = apo
        @uploads = uploads
      end

      def as_json
        {
          access: {},
          type: type,
          administrative: administrative,
          identification: identification,
          structural: structural
        }.tap do |json|
          json[:label] = label if label
        end
      end

      # @return [Request] a clone of this request with the uploads added
      def with_uploads(uploads)
        Request.new(label: label,
                    apo: apo,
                    collection: collection,
                    source_id: source_id,
                    catkey: catkey,
                    type: type,
                    uploads: uploads)
      end

      private

      attr_reader :label, :uploads, :source_id, :catkey, :apo, :collection, :type

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
          hasMember: file_sets_as_json
        }
      end

      # In this case there is a 1-1 mapping between Files and FileSets,
      # but this doesn't always have to be the case.  We could change this in the
      # future so that we have one FileSet that has an Image and its OCR file.
      def file_sets_as_json
        uploads.map { |upload| FileSet.new(uploads: [upload]).as_json }
      end
    end
  end
end

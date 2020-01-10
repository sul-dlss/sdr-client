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
        json = {
          type: type,
          administrative: {
            hasAdminPolicy: apo
          },
          identification: {
            sourceId: source_id
          },
          structural: {
            isMemberOf: collection,
            hasMember: file_sets_as_json
          }
        }
        json[:label] = label if label
        json[:identification][:catkey] = catkey if catkey
        json
      end

      private

      attr_reader :label, :uploads, :source_id, :catkey, :apo, :collection, :type

      # In this case there is a 1-1 mapping between Files and FileSets,
      # but this doesn't always have to be the case.  We could change this in the
      # future so that we have one FileSet that has an Image and its OCR file.
      def file_sets_as_json
        uploads.map do |upload|
          {
            "type": 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            label: upload.filename,
            structural: {
              hasMember: [upload.signed_id]
            }
          }
        end
      end
    end
  end
end
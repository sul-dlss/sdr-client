# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the FileSet metadata that we send to the server for doing a deposit
    class FileSet
      def initialize(uploads:)
        @uploads = uploads
      end

      def as_json
        upload = @uploads.first
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

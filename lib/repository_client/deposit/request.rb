# frozen_string_literal: true

module RepositoryClient
  module Deposit
    # This represents the metadata that we send to the server for doing a deposit
    class Request
      CONTEXT = 'http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld'

      # @param [String] label the required object label
      # @param [String] type (http://cocina.sul.stanford.edu/models/object.jsonld) the required object type.
      # @param [Array<RepositoryClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      def initialize(label:,
                     type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
                     uploads: [])
        @label = label
        @type = type
        @uploads = uploads
      end

      def as_json
        {
          "@context": CONTEXT,
          "@type": type,
          label: label,
          structural: {
            hasMember: file_sets_as_json
          }
        }
      end

      private

      attr_reader :label, :uploads, :type

      # In this case there is a 1-1 mapping between Files and FileSets,
      # but this doesn't always have to be the case.  We could change this in the
      # future so that we have one FileSet that has an Image and its OCR file.
      def file_sets_as_json
        uploads.map do |upload|
          {
            "@context": CONTEXT,
            "@type": 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            label: upload.file_name,
            structural: {
              hasMember: [upload.signed_id]
            }
          }
        end
      end
    end
  end
end

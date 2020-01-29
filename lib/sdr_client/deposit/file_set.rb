# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the FileSet metadata that we send to the server for doing a deposit
    class FileSet
      def initialize(uploads: [], uploads_metadata: {}, files: [], label:)
        @label = label
        @files = if !uploads.empty?
                   uploads.map do |upload|
                     File.new(file_args(upload, uploads_metadata.fetch(upload.filename, {})))
                   end
                 else
                   files
                 end
      end

      def as_json
        {
          "type": 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
          "label": label,
          structural: {
            contains: files.map(&:as_json)
          }
        }
      end

      private

      attr_reader :files, :label

      def file_args(upload, upload_metadata)
        args = {
          external_identifier: upload.signed_id,
          label: upload.filename,
          filename: upload.filename
        }
        args.merge(upload_metadata)
      end
    end
  end
end

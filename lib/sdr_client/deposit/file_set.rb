# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the FileSet metadata that we send to the server for doing a deposit
    class FileSet
      def initialize(uploads: [], files: [])
        @files = if !uploads.empty?
                   uploads.map do |upload|
                     File.new(external_identifier: upload.signed_id, label: upload.filename, filename: upload.filename)
                   end
                 else
                   files
                 end
      end

      def as_json
        {
          "type": 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
          structural: {
            hasMember: files.map(&:as_json)
          }
        }
      end

      private

      attr_reader :files
    end
  end
end

# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the FileSet metadata that we send to the server for doing a deposit
    class FileSet
      # @param [Array] uploads
      # @param [Hash<String,Hash<String,String>>] uploads_metadata the file level metadata
      # @param [Array] files
      # @param [String] label
      def initialize(uploads: [], uploads_metadata: {}, files: [], label:)
        @label = label
        @files = if !uploads.empty?
                   uploads.map do |upload|
                     File.new(**file_args(upload, uploads_metadata.fetch(upload.filename, {})))
                   end
                 else
                   files
                 end
      end

      def as_json
        {
          "type": 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
          "label": label,
          structural: {
            contains: files.map(&:as_json)
          },
          version: 1
        }
      end

      private

      attr_reader :files, :label

      # This creates the metadata for each file and symbolizes the keys
      # @return [Hash<Symbol,String>]
      def file_args(upload, upload_metadata)
        args = {
          external_identifier: upload.signed_id,
          label: upload.filename,
          filename: upload.filename
        }
        args.merge!(upload_metadata)
        # Symbolize
        Hash[args.map { |k, v| [k.to_sym, v] }]
      end
    end
  end
end

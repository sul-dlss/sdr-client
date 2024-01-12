# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # This represents the FileSet metadata that we send to the server for doing a deposit
    class FileSet
      # @param [String] label
      # @param [Array] uploads
      # @param [Hash<String,Hash<String,String>>] uploads_metadata the file level metadata
      # @param [Array] files
      # @param [Class] type_strategy (FileTypeFileSetStrategy) a class that helps us determine how to type the fileset
      def initialize(label:, type_strategy:, uploads: [], uploads_metadata: {}, files: [])
        @label = label
        @type_strategy = type_strategy
        @files = uploads.empty? ? files : files_from(uploads, uploads_metadata)
      end

      def to_h
        {
          type: type_strategy.run(files: files),
          label: label,
          structural: {
            contains: files.map(&:to_h)
          },
          version: 1
        }
      end

      private

      attr_reader :files, :label, :type_strategy

      def files_from(uploads, uploads_metadata)
        uploads.map do |upload|
          SdrClient::RedesignedClient::File.new(**file_args(upload, uploads_metadata.fetch(upload.filename, {})))
        end
      end

      # This creates the metadata for each file and symbolizes the keys
      # @return [Hash<Symbol,String>]
      def file_args(upload, upload_metadata)
        args = {
          external_identifier: upload.signed_id,
          label: ::File.basename(upload.filename),
          filename: upload.filename
        }
        args.merge!(upload_metadata)
        # Symbolize
        args.transform_keys(&:to_sym)
      end
    end
  end
end

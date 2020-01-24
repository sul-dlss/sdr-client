# frozen_string_literal: true

module SdrClient
  module Deposit
    # This strategy is for building one file set per uploaded file
    class DefaultFileSetBuilder
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @param [Hash<String,Hash<String, String>>] files_metadata filename, hash of additional file metadata.
      # @return [Array<SdrClient::Deposit::FileSet>] the uploads transformed to filesets
      def self.run(uploads: [], uploads_metadata: {})
        uploads.each_with_index.map do |upload, i|
          uploads_metadata = { upload.filename => uploads_metadata.fetch(upload.filename, {}) }
          FileSet.new(uploads: [upload], uploads_metadata: uploads_metadata, label: "Object #{i + 1}")
        end
      end
    end
  end
end

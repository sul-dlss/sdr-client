# frozen_string_literal: true

module SdrClient
  module Deposit
    # This strategy is for building one file set per uploaded file
    class DefaultFileSetBuilder
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<SdrClient::Deposit::FileSet>] the uploads transformed to filesets
      def self.run(uploads: [])
        uploads.each_with_index.map do |upload, i|
          FileSet.new(uploads: [upload], label: "Object #{i + 1}")
        end
      end
    end
  end
end

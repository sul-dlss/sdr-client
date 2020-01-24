# frozen_string_literal: true

module SdrClient
  module Deposit
    # This strategy is for building one file set per uploaded file
    class DefaultFileSetBuilder
      # @return [Request] request The initial request
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Request] a clone of this request with the uploads added
      def self.run(request:, uploads: [])
        file_sets = uploads.each_with_index.map do |upload, i|
          FileSet.new(uploads: [upload], label: "Object #{i + 1}")
        end
        request.with_file_sets(file_sets)
      end
    end
  end
end

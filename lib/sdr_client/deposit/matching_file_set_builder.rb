# frozen_string_literal: true

module SdrClient
  module Deposit
    # This stragegy is for building one file set per set of similarly prefixed uploaded files
    class MatchingFileSetBuilder
      # @return [Request] request The initial request
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Request] a clone of this request with the uploads added
      def self.run(request:, uploads: [])
        grouped_files = uploads.group_by { |ul| ::File.basename(ul.filename, '.*') }.each_with_index
        file_sets = grouped_files.map do |(_prefix, files), i|
          SdrClient::Deposit::FileSet.new(uploads: files, label: "Object #{i + 1}")
        end
        request.with_file_sets(file_sets)
      end
    end
  end
end

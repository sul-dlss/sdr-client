# frozen_string_literal: true

module SdrClient
  module Deposit
    # This stragegy is for building one file set per set of similarly prefixed uploaded files
    class MatchingFileSetBuilder
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<SdrClient::Deposit::FileSet>] the uploads transformed to filesets
      def self.run(uploads: [])
        grouped_files = uploads.group_by { |ul| ::File.basename(ul.filename, '.*') }.each_with_index
        grouped_files.map do |(_prefix, files), i|
          SdrClient::Deposit::FileSet.new(uploads: files, label: "Object #{i + 1}")
        end
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  module Deposit
    # This strategy is for building one file set per set of similarly prefixed uploaded files
    class MatchingFileGroupingStrategy
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<Array<SdrClient::Deposit::Files::DirectUploadResponse>>] uploads the grouped uploaded files.
      def self.run(uploads: [])
        uploads.group_by { |ul| ::File.basename(ul.filename, '.*') }
      end
    end
  end
end

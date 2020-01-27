# frozen_string_literal: true

module SdrClient
  module Deposit
    # This strategy is for building one file set per uploaded file
    class SingleFileGroupingStrategy
      # @param [Array<SdrClient::Deposit::Files::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<Array<SdrClient::Deposit::Files::DirectUploadResponse>>] uploads the grouped uploaded files.
      def self.run(uploads: [])
        uploads.map { |upload| [upload] }
      end
    end
  end
end

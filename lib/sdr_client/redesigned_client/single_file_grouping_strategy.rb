# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # This strategy is for building one file set per uploaded file
    class SingleFileGroupingStrategy
      # @param [Array<SdrClient::RedesignedClient::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<Array<SdrClient::RedesignedClient::DirectUploadResponse>>] uploads the grouped uploaded files.
      def self.run(uploads: [])
        uploads.map { |upload| [upload] }
      end
    end
  end
end

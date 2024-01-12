# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # This strategy is for building one file set per set of similarly prefixed uploaded files
    class MatchingFileGroupingStrategy
      # @param [Array<SdrClient::RedesignedClient::DirectUploadResponse>] uploads the uploaded files to attach.
      # @return [Array<Array<SdrClient::RedesignedClient::DirectUploadResponse>>] uploads the grouped uploaded files.
      def self.run(uploads: [])
        # Call `#values` on the result of the grouping operation because:
        #   1) `StructuralGrouper#build_filesets` expects an array of arrays (not hashes); and
        #   2) the keys aren't used anywhere
        uploads.group_by do |ul|
          ::File.join(::File.dirname(ul.filename), ::File.basename(ul.filename, '.*'))
        end.values
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # This strategy is for building the type of a fileset
    class FileTypeFileSetStrategy
      # @return [String] The URI that represents the type of file_set
      def self.run(...)
        Cocina::Models::FileSetType.file
      end
    end
  end
end

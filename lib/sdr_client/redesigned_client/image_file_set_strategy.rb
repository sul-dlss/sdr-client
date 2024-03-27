# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # This strategy is for building the type of a fileset
    class ImageFileSetStrategy
      # @return [String] The URI that represents the type of file_set
      def self.run(...)
        Cocina::Models::FileSetType.image
      end
    end
  end
end

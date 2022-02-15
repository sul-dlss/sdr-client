# frozen_string_literal: true

module SdrClient
  module Deposit
    # This strategy is for building the type of a fileset
    class ImageFileSetStrategy
      # @param [Array<SdrClient::Deposit::Files>] files the files that are part of this strategy
      # @return [String] The URI that represents the type of file_set
      def self.run(files: [])
        Cocina::Models::Vocab::Resources.image
      end
    end
  end
end

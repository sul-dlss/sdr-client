# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Build basic metadata for files, iterating over a series of operations
    # The available options are here: https://github.com/sul-dlss/sdr-client/blob/v0.8.1/lib/sdr_client/deposit/file.rb#L8-L10
    class StructuralMetadataBuilder
      OPERATIONS = [
        Operations::MimeType,
        Operations::MD5,
        Operations::SHA1
      ].freeze
      private_constant :OPERATIONS

      # @param (see #initialize)
      # @return (see #build)
      def self.build(files:, files_metadata:, basepath:)
        new(files: files, files_metadata: files_metadata.dup, basepath: basepath).build
      end

      # @param [Array<String>] files the list of relative filepaths for which to generate metadata
      def initialize(files:, files_metadata:, basepath:)
        @files = files
        @files_metadata = files_metadata
        @basepath = basepath
      end

      # @return [Hash<String, Hash<String, String>>] a map of relative filepaths to a map of metadata
      def build
        files.each do |filepath|
          OPERATIONS.each do |operation|
            result = operation.for(filepath: absolute_filepath_for(filepath))
            next if result.nil?

            files_metadata[filepath] ||= {}
            files_metadata[filepath][operation::NAME] = result
          end
        end
        files_metadata
      end

      private

      attr_reader :files, :files_metadata, :basepath

      def absolute_filepath_for(filepath)
        ::File.join(basepath, filepath)
      end
    end
  end
end

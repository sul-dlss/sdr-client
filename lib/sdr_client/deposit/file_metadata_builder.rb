# frozen_string_literal: true

require 'sdr_client/deposit/file_metadata_builder_operations/mime_type'
require 'sdr_client/deposit/file_metadata_builder_operations/md5'
require 'sdr_client/deposit/file_metadata_builder_operations/sha1'

module SdrClient
  module Deposit
    # Build basic metadata for files, iterating over a series of operations
    # The available options are here: https://github.com/sul-dlss/sdr-client/blob/v0.8.1/lib/sdr_client/deposit/file.rb#L8-L10
    class FileMetadataBuilder
      OPERATIONS = [
        FileMetadataBuilderOperations::MimeType,
        FileMetadataBuilderOperations::MD5,
        FileMetadataBuilderOperations::SHA1
      ].freeze
      private_constant :OPERATIONS

      # @param (see #initialize)
      # @return (see #build)
      def self.build(files:, files_metadata:)
        new(files: files, files_metadata: files_metadata.dup).build
      end

      # @param [Array<String>] files the list of files for which to generate metadata
      def initialize(files:, files_metadata:)
        @files = files
        @files_metadata = files_metadata
      end

      # @return [Hash<String, Hash<String, String>>]
      def build
        files.each do |file_path|
          OPERATIONS.each do |operation|
            result = operation.for(file_path: file_path)
            next if result.nil?

            files_metadata[file_path] ||= {}
            files_metadata[file_path][operation::NAME] = result
          end
        end
        files_metadata
      end

      private

      attr_reader :files, :files_metadata
    end
  end
end

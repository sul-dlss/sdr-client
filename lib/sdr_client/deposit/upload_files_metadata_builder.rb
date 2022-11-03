# frozen_string_literal: true

require 'logger'

module SdrClient
  module Deposit
    # Collecting all the metadata about the files for a deposit
    class UploadFilesMetadataBuilder
      # @param [Array<String>] files a list of filepaths to upload
      # @param [Hash<String,String>] mime_types a map of filenames to mime types
      # @return [Hash<String, Files::DirectUploadRequest>] the metadata for uploading the files
      def self.build(files:, mime_types:)
        new(files: files, mime_types: mime_types).build
      end

      # @param [Array<String>] files a list of filepaths to upload
      # @param [Hash<String,String>] mime_types a map of filenames to mime types
      def initialize(files:, mime_types:)
        @files = files
        @mime_types = mime_types
      end

      attr_reader :files, :mime_types

      # @return [Hash<String, Files::DirectUploadRequest>] the metadata for uploading the files
      def build
        files.each_with_object({}) do |path, obj|
          obj[path] = Files::DirectUploadRequest.from_file(path,
                                                           file_name: filename_for(path),
                                                           content_type: mime_type_for(path))
        end
      end

      # This can be overridden in the case that the file on disk has a different
      # name than we want to repo to know about.
      def filename_for(file_path)
        file_path
      end

      def mime_type_for(file_path)
        mime_types[filename_for(file_path)]
      end
    end
  end
end

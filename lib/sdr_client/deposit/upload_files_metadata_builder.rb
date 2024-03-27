# frozen_string_literal: true

module SdrClient
  module Deposit
    # Collecting all the metadata about the files for a deposit
    class UploadFilesMetadataBuilder
      # @param [Array<String>] files a list of relative filepaths to upload
      # @param [Hash<String,String>] mime_types a map of filenames to mime types
      # @param [String] basepath path to which files are relative
      # @return [Hash<String, Files::DirectUploadRequest>] the metadata for uploading the files
      def self.build(files:, mime_types:, basepath:)
        new(files: files, mime_types: mime_types, basepath: basepath).build
      end

      # @param [Array<String>] files a list of absolute filepaths to upload
      # @param [Hash<String,String>] mime_types a map of filenames to mime types
      # @param [String] basepath path to which files are relative
      def initialize(files:, mime_types:, basepath:)
        @files = files
        @mime_types = mime_types
        @basepath = basepath
      end

      attr_reader :files, :mime_types, :basepath

      # @return [Hash<String, Files::DirectUploadRequest>] the metadata for uploading the files
      def build
        files.each_with_object({}) do |filepath, obj|
          obj[filepath] = Files::DirectUploadRequest.from_file(absolute_filepath_for(filepath),
                                                               file_name: filepath,
                                                               content_type: mime_types[filepath])
        end
      end

      def absolute_filepath_for(filepath)
        ::File.join(basepath, filepath)
      end
    end
  end
end

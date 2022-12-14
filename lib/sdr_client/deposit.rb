# frozen_string_literal: true

require 'logger'

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    BOOK_TYPE = Cocina::Models::ObjectType.book
    # rubocop:disable Metrics/ParameterLists
    # rubocop:disable Metrics/MethodLength
    # params [Array<String>] files a list of relative filepaths to upload
    # params [String] basepath filepath to which filepaths are relative, defaults to current directory
    # params [Hash<String,Hash>] file_metadata relative filepath, hash of metadata per-file metadata
    # @return [String] job id for the background job result
    def self.run(label: nil,
                 type: BOOK_TYPE,
                 viewing_direction: nil,
                 view: 'dark',
                 download: 'none',
                 use_and_reproduction: nil,
                 copyright: nil,
                 apo:,
                 collection: nil,
                 catkey: nil,
                 embargo_release_date: nil,
                 embargo_access: 'world',
                 embargo_download: 'world',
                 source_id:,
                 url:,
                 files: [],
                 files_metadata: {},
                 basepath: Dir.getwd,
                 accession: false,
                 priority: nil,
                 grouping_strategy: SingleFileGroupingStrategy,
                 file_set_type_strategy: FileTypeFileSetStrategy,
                 logger: Logger.new($stdout))
      # augmented_metadata is a map of relative filepaths to file metadata
      augmented_metadata = FileMetadataBuilder.build(files: files, files_metadata: files_metadata, basepath: basepath)
      request = Request.new(label: label,
                            type: type,
                            view: view,
                            download: download,
                            apo: apo,
                            use_and_reproduction: use_and_reproduction,
                            copyright: copyright,
                            collection: collection,
                            source_id: source_id,
                            catkey: catkey,
                            embargo_release_date: embargo_release_date,
                            embargo_access: embargo_access,
                            embargo_download: embargo_download,
                            viewing_direction: viewing_direction,
                            files_metadata: augmented_metadata)
      connection = Connection.new(url: url)
      Process.new(metadata: request,
                  connection: connection,
                  files: files,
                  basepath: basepath,
                  grouping_strategy: grouping_strategy,
                  file_set_type_strategy: file_set_type_strategy,
                  accession: accession,
                  priority: priority,
                  logger: logger).run
    end
    # rubocop:enable Metrics/MethodLength

    # @param [Array<String>] files relative paths to files
    # @params [String] basepath path to which files are relative
    def self.model_run(request_dro:,
                       files: [],
                       basepath: Dir.getwd,
                       url:,
                       accession:,
                       priority: nil,
                       logger: Logger.new($stdout))
      connection = Connection.new(url: url)
      ModelProcess.new(request_dro: request_dro,
                       connection: connection,
                       files: files,
                       basepath: basepath,
                       logger: logger,
                       accession: accession,
                       priority: priority).run
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
require 'json'
require 'sdr_client/deposit/create_resource'
require 'sdr_client/deposit/single_file_grouping_strategy'
require 'sdr_client/deposit/matching_file_grouping_strategy'
require 'sdr_client/deposit/file_type_file_set_strategy'
require 'sdr_client/deposit/image_file_set_strategy'
require 'sdr_client/deposit/files/direct_upload_request'
require 'sdr_client/deposit/files/direct_upload_response'
require 'sdr_client/deposit/file'
require 'sdr_client/deposit/file_metadata_builder'
require 'sdr_client/deposit/file_set'
require 'sdr_client/deposit/request'
require 'sdr_client/deposit/metadata_builder'
require 'sdr_client/deposit/model_process'
require 'sdr_client/deposit/process'
require 'sdr_client/deposit/update_resource'
require 'sdr_client/deposit/update_dro_with_file_identifiers'
require 'sdr_client/deposit/upload_files'
require 'sdr_client/deposit/upload_files_metadata_builder'

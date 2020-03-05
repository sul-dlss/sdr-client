# frozen_string_literal: true

require 'logger'

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    # rubocop:disable Metrics/ParameterLists
    # rubocop:disable Metrics/MethodLength
    def self.run(label: nil,
                 type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                 viewing_direction: nil,
                 access: 'dark',
                 use_statement: nil,
                 copyright: nil,
                 apo:,
                 collection: nil,
                 catkey: nil,
                 embargo_release_date: nil,
                 embargo_access: 'world',
                 source_id:,
                 url:,
                 files: [],
                 files_metadata: {},
                 grouping_strategy: SingleFileGroupingStrategy,
                 logger: Logger.new(STDOUT))
      token = Credentials.read

      augmented_metadata = FileMetadataBuilder.build(files: files, files_metadata: files_metadata)
      metadata = Request.new(label: label,
                             type: type,
                             access: access,
                             apo: apo,
                             use_statement: use_statement,
                             copyright: copyright,
                             collection: collection,
                             source_id: source_id,
                             catkey: catkey,
                             embargo_release_date: embargo_release_date,
                             embargo_access: embargo_access,
                             viewing_direction: viewing_direction,
                             files_metadata: augmented_metadata)
      Process.new(metadata: metadata, url: url, token: token, files: files,
                  grouping_strategy: grouping_strategy, logger: logger).run
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/ParameterLists
  end
end
require 'json'
require 'sdr_client/deposit/single_file_grouping_strategy'
require 'sdr_client/deposit/matching_file_grouping_strategy'
require 'sdr_client/deposit/files/direct_upload_request'
require 'sdr_client/deposit/files/direct_upload_response'
require 'sdr_client/deposit/file'
require 'sdr_client/deposit/file_metadata_builder'
require 'sdr_client/deposit/file_set'
require 'sdr_client/deposit/request'
require 'sdr_client/deposit/upload_files'
require 'sdr_client/deposit/metadata_builder'
require 'sdr_client/deposit/process'

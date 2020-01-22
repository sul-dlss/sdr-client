# frozen_string_literal: true

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    def self.run(label: nil,
                 type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                 apo:,
                 collection:,
                 catkey: nil,
                 source_id:,
                 url:, files: [])
      token = Credentials.read

      metadata = Request.new(label: label,
                             type: type,
                             apo: apo,
                             collection: collection,
                             source_id: source_id,
                             catkey: catkey)
      Process.new(metadata: metadata, url: url, token: token, files: files).run
    end
  end
end
require 'json'
require 'sdr_client/deposit/files/direct_upload_request'
require 'sdr_client/deposit/files/direct_upload_response'
require 'sdr_client/deposit/file'
require 'sdr_client/deposit/file_set'
require 'sdr_client/deposit/request'
require 'sdr_client/deposit/process'

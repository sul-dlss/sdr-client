# frozen_string_literal: true

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    def self.run(label: nil,
                 type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                 apo:,
                 collection:,
                 catkey:,
                 source_id:,
                 url:, files: [])
      Process.new(label: label, type: type, url: url, files: files,
                  apo: apo, collection: collection, catkey: catkey, source_id: source_id).run
    end
  end
end
require 'json'
require 'sdr_client/deposit/files/direct_upload_request'
require 'sdr_client/deposit/files/direct_upload_response'
require 'sdr_client/deposit/request'
require 'sdr_client/deposit/process'

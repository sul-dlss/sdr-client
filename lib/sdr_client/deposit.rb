# frozen_string_literal: true

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    def self.run(label:,
                 type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                 url:, files: [])
      Process.new(label: label, type: type, url: url, files: files).run
    end
  end
end
require 'json'
require 'sdr_client/deposit/files/direct_upload_request'
require 'sdr_client/deposit/files/direct_upload_response'
require 'sdr_client/deposit/request'
require 'sdr_client/deposit/process'

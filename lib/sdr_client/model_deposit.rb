# frozen_string_literal: true

require 'logger'

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    def self.model_run(request_dro:,
                       files: [],
                       url:,
                       accession:,
                       logger: Logger.new(STDOUT))
      connection = Connection.new(url: url)
      ModelProcess.new(request_dro: request_dro,
                       connection: connection,
                       files: files,
                       logger: logger,
                       accession: accession).run
    end
  end
end
require 'sdr_client/deposit/model_process'

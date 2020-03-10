# frozen_string_literal: true

require 'logger'

module SdrClient
  # The namespace for the "deposit" command
  module Deposit
    def self.model_run(request_dro:,
                       files: [],
                       url:,
                       logger: Logger.new(STDOUT))
      token = Credentials.read

      ModelProcess.new(request_dro: request_dro, url: url, token: token, files: files, logger: logger).run
    end
  end
end
require 'sdr_client/deposit/model_process'

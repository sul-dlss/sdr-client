# frozen_string_literal: true

module RepositoryClient
  # The command line interface
  module CLI
    def self.start(command, options)
      case command
      when 'deposit'
        RepositoryClient::Deposit.run(options)
      end
    end
  end
end

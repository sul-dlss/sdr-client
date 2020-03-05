# frozen_string_literal: true

require 'digest'

module SdrClient
  module Deposit
    module FileMetadataBuilderOperations
      # SHA1 for this file.
      class SHA1
        NAME = 'sha1'
        def self.for(file_path:, **)
          Digest::SHA1.file(file_path).hexdigest
        end
      end
    end
  end
end

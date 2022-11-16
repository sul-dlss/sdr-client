# frozen_string_literal: true

require 'digest'

module SdrClient
  module Deposit
    module FileMetadataBuilderOperations
      # MD5 for this file.
      class MD5
        NAME = 'md5'
        def self.for(filepath:, **)
          Digest::MD5.file(filepath).hexdigest
        end
      end
    end
  end
end

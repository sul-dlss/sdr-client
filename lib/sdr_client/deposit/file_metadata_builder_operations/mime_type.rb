# frozen_string_literal: true

require 'digest'

module SdrClient
  module Deposit
    module FileMetadataBuilderOperations
      # Mime-type for this file.
      class MimeType
        NAME = 'mime_type'
        def self.for(file_path:, **)
          `file --mime-type -b #{file_path}`.chomp
        end
      end
    end
  end
end

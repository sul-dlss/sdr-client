# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    module Operations
      # SHA1 for this file.
      class SHA1
        NAME = 'sha1'

        def self.for(filepath:, **)
          Digest::SHA1.file(filepath).hexdigest
        end
      end
    end
  end
end

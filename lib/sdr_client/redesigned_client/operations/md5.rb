# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    module Operations
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

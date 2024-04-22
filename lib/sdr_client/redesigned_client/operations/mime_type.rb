# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    module Operations
      # Mime-type for this file.
      class MimeType
        NAME = 'mime_type'

        def self.for(filepath:, **)
          argv = Shellwords.escape(filepath)
          `file --mime-type -b #{argv}`.chomp
        end
      end
    end
  end
end

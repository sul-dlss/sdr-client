# frozen_string_literal: true

require 'digest'

module SdrClient
  module Deposit
    module Files
      DirectUploadRequest = Struct.new(:checksum, :byte_size, :content_type, :filename, keyword_init: true) do
        def self.from_file(filename)
          checksum = Digest::MD5.file(filename).base64digest
          new(checksum: checksum,
              byte_size: File.size(filename),
              content_type: 'text/html',
              filename: File.basename(filename))
        end

        def as_json
          {
            blob: { filename: filename, byte_size: byte_size, checksum: checksum, content_type: content_type }
          }
        end

        def to_json(*_args)
          JSON.generate(as_json)
        end
      end
    end
  end
end

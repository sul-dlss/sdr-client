# frozen_string_literal: true

require 'digest'

module SdrClient
  module Deposit
    module Files
      DirectUploadRequest = Struct.new(:checksum, :byte_size, :content_type, :filename, keyword_init: true) do
        def self.from_file(path, file_name:, content_type:)
          checksum = Digest::MD5.file(path).base64digest
          new(checksum: checksum,
              byte_size: ::File.size(path),
              content_type: content_type || 'application/octet-stream',
              filename: file_name)
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

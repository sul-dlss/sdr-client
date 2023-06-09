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
              content_type: clean_content_type(content_type),
              filename: file_name)
        end

        def as_json
          {
            blob: { filename: filename, byte_size: byte_size, checksum: checksum,
                    content_type: self.class.clean_content_type(content_type) }
          }
        end

        def to_json(*_args)
          JSON.generate(as_json)
        end

        def self.clean_content_type(content_type)
          # Invalid JSON files with a content type of application/json will trigger 400 errors in sdr-api
          # since they are parsed and rejected (not clear why and what part of the stack is doing this).
          # The work around is to change the content_type for any JSON files to something different and
          # specific to avoid the parsing, and thaen have this changed back to application/json after .
          # upload is complete. There is a similar change in sdr-api to change the content_type back.
          # See https://github.com/sul-dlss/happy-heron/issues/3075 for the original bug report
          # See https://github.com/sul-dlss/sdr-api/pull/585 for the change in sdr-api
          return 'application/octet-stream' if content_type.blank?

          return 'application/x-stanford-json' if content_type == 'application/json'

          # ActiveStorage is expecting "application/x-stata-dta" not "application/x-stata-dta;version=14"
          content_type.split(';')&.first
        end
      end
    end
  end
end

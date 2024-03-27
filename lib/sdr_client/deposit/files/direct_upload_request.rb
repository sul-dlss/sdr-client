# frozen_string_literal: true

module SdrClient
  module Deposit
    module Files
      DirectUploadRequest = Struct.new(:checksum, :byte_size, :content_type, :filename, keyword_init: true) do
        def self.from_file(path, file_name:, content_type:)
          checksum = Digest::MD5.file(path).base64digest
          new(checksum: checksum,
              byte_size: ::File.size(path),
              content_type: clean_and_translate_content_type(content_type),
              filename: file_name)
        end

        def as_json
          {
            blob: { filename: filename, byte_size: byte_size, checksum: checksum,
                    content_type: self.class.clean_and_translate_content_type(content_type) }
          }
        end

        def to_json(*_args)
          JSON.generate(as_json)
        end

        # Invalid JSON files with a content type of application/json will trigger 400 errors in sdr-api
        # since they are parsed and rejected (not clear why and what part of the stack is doing this).
        # The work around is to change the content_type for any JSON files to a custom stand-in and
        # specific to avoid the parsing, and then have this translated back to application/json after .
        # upload is complete. There is a corresponding change in sdr-api to translate the content_type back
        # before the Cocina is saved.
        # See https://github.com/sul-dlss/happy-heron/issues/3075 for the original bug report
        # See https://github.com/sul-dlss/sdr-api/pull/585 for the change in sdr-api
        def self.clean_and_translate_content_type(content_type)
          return 'application/octet-stream' if content_type.blank?

          # ActiveStorage is expecting "application/x-stata-dta" not "application/x-stata-dta;version=14"
          content_type = content_type.split(';')&.first

          content_type == 'application/json' ? 'application/x-stanford-json' : content_type
        end
      end
    end
  end
end

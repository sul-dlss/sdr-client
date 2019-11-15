# frozen_string_literal: true

module RepositoryClient
  module Deposit
    module Files
      DirectUploadRequest = Struct.new(:checksum, :byte_size, :content_type, :file_name)
    end
  end
end

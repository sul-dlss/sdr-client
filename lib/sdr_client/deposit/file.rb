# frozen_string_literal: true

module SdrClient
  module Deposit
    # This represents the File metadata that we send to the server for doing a deposit
    class File
      def initialize(external_identifier:, label:, filename:, access: 'dark', preserve: false, shelve: false)
        @external_identifier = external_identifier
        @label = label
        @filename = filename
        @access = access
        @preserve = preserve
        @shelve = shelve
      end

      def as_json
        {
          "type": 'http://cocina.sul.stanford.edu/models/file.jsonld',
          label: @label,
          filename: @filename,
          externalIdentifier: @external_identifier,
          access: {
            access: @access
          },
          administrative: {
            sdrPreserve: @preserve,
            shelve: @shelve
          }
        }
      end
    end
  end
end

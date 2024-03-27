# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    class CLI < Thor
      # The stored credentials
      class Credentials
        # @param [String] a json string that contains a field 'token'
        def self.write(body)
          token = JSON.parse(body).fetch('token')
          FileUtils.mkdir_p(credentials_path, mode: 0o700)
          File.atomic_write(credentials_file) { |file| file.write(token) }
          File.chmod(0o600, credentials_file)
        end

        def self.read
          return unless ::File.exist?(credentials_file)

          creds = File.read(credentials_file, chomp: true)
          return if creds.nil?

          creds
        end

        def self.credentials_path
          @credentials_path ||= File.join(Dir.home, '.sdr')
        end

        def self.credentials_file
          File.join(credentials_path, 'credentials')
        end
      end
    end
  end
end

# frozen_string_literal: true

module SdrClient
  # The stored credentials
  class Credentials
    class NoCredentialsError < StandardError; end

    # @param [String] a json string that contains a field 'token'
    def self.write(body)
      json = JSON.parse(body)
      FileUtils.mkdir_p(credentials_path, mode: 0o700)
      File.atomic_write(credentials_file) do |file|
        file.write(json.fetch('token'))
      end
      File.chmod(0o600, credentials_file)
    end

    def self.read
      raise NoCredentialsError unless ::File.exist?(credentials_file)

      creds = File.readlines(credentials_file, chomp: true).first if ::File.exist?(credentials_file)
      raise NoCredentialsError if creds.nil?

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

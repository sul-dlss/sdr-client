# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sdr_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'sdr-client'
  spec.version       = SdrClient::VERSION
  spec.authors       = ['Justin Coyne']
  spec.email         = ['jcoyne@justincoyne.com']

  spec.summary       = 'The CLI for https://github.com/sul-dlss/sdr-api'
  spec.description   = 'This provides a way to deposit repository objects into the Stanford Digital Repository'
  spec.homepage      = 'https://github.com/sul-dlss/sdr-client'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sul-dlss/sdr-client'
  spec.metadata['changelog_uri'] = 'https://github.com/sul-dlss/sdr-client/releases'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'cocina-models', '~> 0.107.0'
  spec.add_dependency 'config'
  spec.add_dependency 'dry-monads'
  spec.add_dependency 'faraday', '>= 0.16'
  spec.add_dependency 'launchy'
  spec.add_dependency 'zeitwerk'

  spec.metadata['rubygems_mfa_required'] = 'true'
end

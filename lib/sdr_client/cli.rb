# frozen_string_literal: true

require 'launchy'
require 'thor'
require_relative 'cli/config'

module SdrClient
  # The SDR command-line interface
  class CLI < Thor
    include Thor::Actions

    # Make sure Thor commands preserve exit statuses
    # @see https://github.com/rails/thor/wiki/Making-An-Executable
    def self.exit_on_failure?
      true
    end

    # Print out help and exit with error code if command not found
    def self.handle_no_command_error(command)
      puts "Command '#{command}' not found, displaying help:"
      puts
      puts help
      exit(1)
    end

    def self.default_url
      'https://sdr-api-prod.stanford.edu'
    end

    package_name 'sdr'

    class_option :url, desc: 'URL of SDR API endpoint', type: :string, default: default_url

    desc 'get DRUID', 'Retrieve an object from the SDR'
    def get(druid)
      rescue_expected_exceptions do
        say Find.run(druid, url: options[:url], logger: Logger.new($stderr))
      end
    end

    desc 'login', 'Open authentication proxy UI, or prompt for username and password, and then prompt for token (saved in ~/.sdr/credentials)'
    def login
      authentication_proxy_url ? login_via_proxy : login_via_credentials
    end

    desc 'version', 'Display the SDR CLI version'
    def version
      say VERSION
    end

    desc 'update DRUID', 'Update an object in the SDR'
    option :skip_polling, type: :boolean, default: false, aliases: '-s', desc: 'Print out job ID instead of polling for result'
    option :apo, desc: 'Druid identifier of the admin policy object', aliases: '--admin-policy'
    option :collection, desc: 'Druid identifier of the collection object'
    option :copyright, desc: 'Copyright statement'
    option :use_and_reproduction, desc: 'Use and reproduction statement'
    option :license, desc: 'License URI'
    option :view, enum: %w[world stanford location-based citation-only dark], desc: 'Access view level for the object'
    option :download, enum: %w[world stanford location-based none], desc: 'Access download level for the object'
    option :location, enum: %w[spec music ars art hoover m&m], desc: 'Access location for the object'
    option :cdl, type: :boolean, default: false, desc: 'Controlled digital lending'
    option :cocina_file, desc: 'Path to a file containing Cocina JSON'
    option :cocina_pipe, type: :boolean, default: false, desc: 'Indicate Cocina JSON is being piped in'
    option :basepath, default: Dir.getwd, desc: 'Base path for the files'
    def update(druid)
      rescue_expected_exceptions do
        validate_druid!(druid)
        job_id = Update.run(druid, **options)
        poll_for_job_complete(job_id: job_id, url: options[:url])
      end
    end

    desc 'deposit OPTIONAL_FILES', 'Deposit (accession) an object into the SDR'
    option :skip_polling, type: :boolean, default: false, aliases: '-s', desc: 'Print out job ID instead of polling for result'
    option :apo, required: true, desc: 'Druid identifier of the admin policy object', aliases: '--admin-policy'
    option :source_id, required: true, desc: 'Source ID for this object'
    option :label, desc: 'Object label'
    option :type, enum: %w[image book document map manuscript media three_dimensional object collection admin_policy], desc: 'The object type'
    option :collection, desc: 'Druid identifier of the collection object'
    option :catkey, desc: 'Symphony catkey for this item'
    option :folio_instance_hrid, desc: 'Folio instance HRID for this item'
    option :copyright, desc: 'Copyright statement'
    option :use_and_reproduction, desc: 'Use and reproduction statement'
    option :viewing_direction, enum: %w[left-to-right right-to-left], desc: 'Viewing direction (if a book)'
    option :view, enum: %w[world stanford location-based citation-only dark], desc: 'Access view level for the object'
    option :download, enum: %w[world stanford location-based none], desc: 'Access download level for the object'
    option :location, enum: %w[spec music ars art hoover m&m], desc: 'Access location for the object'
    option :files_metadata, desc: 'JSON string representing per-file metadata'
    option :grouping_strategy, enum: %w[default filename], desc: 'Strategy for grouping files into filesets'
    option :basepath, default: Dir.getwd, desc: 'Base path for the files'
    def deposit(*files)
      register_or_deposit(files: files, accession: true)
    end

    desc 'register OPTIONAL_FILES', 'Create a draft object in the SDR and retrieve a Druid identifier'
    option :skip_polling, type: :boolean, default: false, aliases: '-s', desc: 'Print out job ID instead of polling for result'
    option :apo, required: true, desc: 'Druid identifier of the admin policy object', aliases: '--admin-policy'
    option :source_id, required: true, desc: 'Source ID for this object'
    option :label, desc: 'Object label'
    option :type, enum: %w[image book document map manuscript media three_dimensional object collection admin_policy], desc: 'The object type'
    option :collection, desc: 'Druid identifier of the collection object'
    option :catkey, desc: 'Symphony catkey for this item'
    option :folio_instance_hrid, desc: 'Folio instance HRID for this item'
    option :copyright, desc: 'Copyright statement'
    option :use_and_reproduction, desc: 'Use and reproduction statement'
    option :viewing_direction, enum: %w[left-to-right right-to-left], desc: 'Viewing direction (if a book)'
    option :view, enum: %w[world stanford location-based citation-only dark], desc: 'Access view level for the object'
    option :files_metadata, desc: 'JSON string representing per-file metadata'
    option :grouping_strategy, enum: %w[default filename], desc: 'Strategy for grouping files into filesets'
    option :basepath, default: Dir.getwd, desc: 'Base path for the files'
    def register(*files)
      register_or_deposit(files: files, accession: false)
    end

    private

    def rescue_expected_exceptions
      yield
    rescue UnexpectedResponse::TokenExpired
      say_error 'Token has expired! Please log in again.'
      exit(1)
    rescue Credentials::NoCredentialsError
      say_error 'No token found! Please log in first.'
      exit(1)
    end

    def login_via_proxy
      say 'Opened the configured authentication proxy in your browser. Once there, generate a new token and copy the entire value.'
      Launchy.open(authentication_proxy_url)
      # Some CLI environments will pop up a message about opening the URL in
      # an existing browse. Since this is OS-dependency, and not something
      # we can control via Launchy, just wait a bit before rendering the
      # `ask` prompt so it's clearer to the user what's happening
      sleep 0.5
      token_string = ask('Paste token here:')
      Credentials.write(token_string)
      expiry = JSON.parse(token_string)['exp']
      say "You are now authenticated for #{options[:url]} until #{expiry}"
    rescue StandardError => e
      say_error "Error logging in via proxy: #{e}"
      exit(1)
    end

    def login_via_credentials
      status = Login.run(
        url: options[:url],
        login_service: lambda do
          {
            email: ask('Email:'),
            password: ask('Password:', echo: false)
          }
        end
      )

      return puts unless status.failure?

      say_error status.failure
      exit(1)
    end

    def authentication_proxy_url
      @authentication_proxy_url ||= Settings.authentication_proxy_url[options[:url]]
    end

    def register_or_deposit(files:, accession:)
      rescue_expected_exceptions do
        opts = munge_options(options, files)
        skip_polling = opts.delete(:skip_polling)
        job_id = Deposit.run(accession: accession, **opts)
        return if skip_polling

        poll_for_job_complete(job_id: job_id, url: opts[:url])
      end
    end

    def munge_options(options, files)
      options.to_h.symbolize_keys.tap do |opts|
        opts[:files] = expand_files(files) if files.present?
        opts[:type] = Cocina::Models::ObjectType.public_send(options[:type]) if options[:type]
        opts[:files_metadata] = JSON.parse(options[:files_metadata]) if options[:files_metadata]
        if options[:grouping_strategy]
          opts[:grouping_strategy] = if options[:grouping_strategy] == 'filename'
                                       Deposit::MatchingFileGroupingStrategy
                                     else
                                       Deposit::SingleFileGroupingStrategy
                                     end
        end
      end
    end

    def expand_files(files)
      files.map do |file|
        if Dir.exist?(file)
          Dir.glob("#{file}/**/*").select { |f| File.file?(f) }
        else
          file
        end
      end.flatten
    end

    def validate_druid!(druid)
      return if druid.present?

      say_error "Not a valid druid: #{druid.inspect}"
      exit(1)
    end

    def poll_for_job_complete(job_id:, url:)
      # the extra args to `say` prevent appending a newline
      say('SDR is processing your request.', nil, false)
      result = nil
      1.upto(60) do
        result = BackgroundJobResults.show(url: url, job_id: job_id)
        break unless %w[pending processing].include?(result['status'])

        # the extra args to `say` prevent appending a newline
        say('.', nil, false)
        sleep 1
      end

      if result['status'] == 'complete'
        if (errors = result.dig('output', 'errors'))
          say_error " errored! #{errors}"
        else
          say " success! (druid: #{result.dig('output', 'druid')})"
        end
      else
        say_error " job #{job_id} did not complete\n#{result.inspect}"
      end
    end
  end
end

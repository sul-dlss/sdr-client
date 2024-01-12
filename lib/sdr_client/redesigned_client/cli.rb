# frozen_string_literal: true

require 'byebug'
require 'launchy'
require 'thor'
require_relative 'cli/config'
require_relative 'cli/credentials'
require_relative 'cli/update'

module SdrClient
  class RedesignedClient
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
        say client.find(object_id: druid)
      end

      desc 'version', 'Display the SDR CLI version'
      def version
        say VERSION
      end

      desc 'update DRUID', 'Update an object in the SDR'
      option :skip_polling, type: :boolean, default: false, aliases: '-s',
                            desc: 'Print out job ID instead of polling for result'
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
        validate_druid!(druid)
        # Make sure client is configured
        client
        job_id = CLI::Update.run(druid, **options)
        if options[:skip_polling]
          say "job ID #{job_id} queued (not polling because `-s` flag was supplied)"
          return
        end

        job_status = client.job_status(job_id: job_id)
        if job_status.wait_until_complete
          say "success! (druid: #{job_status.druid})"
        else
          say_error "errored! #{job_status.errors}"
        end
      end

      desc 'deposit OPTIONAL_FILES', 'Deposit (accession) an object into the SDR'
      option :skip_polling, type: :boolean, default: false, aliases: '-s',
                            desc: 'Print out job ID instead of polling for result'
      option :apo, required: true, desc: 'Druid identifier of the admin policy object', aliases: '--admin-policy'
      option :source_id, required: true, desc: 'Source ID for this object'
      option :label, desc: 'Object label'
      option :type, enum: %w[image book document map manuscript media three_dimensional object collection admin_policy],
                    desc: 'The object type'
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
      def deposit(*files)
        register_or_deposit(files: files, accession: true)
      end

      desc 'register OPTIONAL_FILES', 'Create a draft object in the SDR and retrieve a Druid identifier'
      option :skip_polling, type: :boolean, default: false, aliases: '-s',
                            desc: 'Print out job ID instead of polling for result'
      option :apo, required: true, desc: 'Druid identifier of the admin policy object', aliases: '--admin-policy'
      option :source_id, required: true, desc: 'Source ID for this object'
      option :label, desc: 'Object label'
      option :type, enum: %w[image book document map manuscript media three_dimensional object collection admin_policy],
                    desc: 'The object type'
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

      def client
        SdrClient::RedesignedClient.configure(
          url: options[:url],
          token: Credentials.read || SdrClient::RedesignedClient.default_token,
          token_refresher: -> { login_via_proxy }
        )
      end

      def login_via_proxy
        say 'Opened the configured authentication proxy in your browser. ' \
            'Once there, generate a new token and copy the entire value.'
        Launchy.open(authentication_proxy_url)
        # Some CLI environments will pop up a message about opening the URL in
        # an existing browse. Since this is OS-dependency, and not something
        # we can control via Launchy, just wait a bit before rendering the
        # `ask` prompt so it's clearer to the user what's happening
        sleep 0.5
        token_string = ask('Paste token here:')
        expiry = JSON.parse(token_string)['exp']
        CLI::Credentials.write(token_string)
        say "You are now authenticated for #{options[:url]} until #{expiry}"
        token_string
      end

      def authentication_proxy_url
        Settings.authentication_proxy_url[options[:url]]
      end

      def register_or_deposit(files:, accession:)
        opts = munge_options(options, files, accession)
        job_id = client.build_and_deposit(apo: options[:apo], source_id: options[:source_id], **opts)
        if opts.delete(:skip_polling)
          say "job ID #{job_id} queued (not polling because `-s` flag was supplied)"
          return
        end

        job_status = client.job_status(job_id: job_id)
        if job_status.wait_until_complete
          say "success! (druid: #{job_status.druid})"
        else
          say_error "errored! #{job_status.errors}"
        end
      end

      def munge_options(options, files, accession)
        options.to_h.symbolize_keys.tap do |opts|
          opts[:access] = accession
          opts[:type] = Cocina::Models::ObjectType.public_send(options[:type]) if options[:type]
          opts[:files] = expand_files(files) if files.present?
          opts[:files_metadata] = JSON.parse(options[:files_metadata]) if options[:files_metadata]
          opts.delete(:apo)
          opts.delete(:source_id)
        end
      end

      def expand_files(files)
        files.flat_map do |file|
          next file unless Dir.exist?(file)

          Dir.glob("#{file}/**/*").select { |f| File.file?(f) }
        end
      end

      def validate_druid!(druid)
        return if druid.present?

        say_error "Not a valid druid: #{druid.inspect}"
        exit(1)
      end
    end
  end
end

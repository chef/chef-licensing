require "chef-config/windows"
require "chef-config/path_helper"
require "yaml"
require "date"
require "fileutils" unless defined?(FileUtils)
require_relative "../license_key_fetcher"
require_relative "../config"
require_relative "../exceptions/license_file_corrupted"
require_relative "license_file/v4"
require_relative "license_file/v3"
require_relative "../exceptions/invalid_file_format_version"

module ChefLicensing
  class LicenseKeyFetcher

    # Represents a fethced license ID recorded on disk
    class File
      LICENSE_KEY_FILE = "licenses.yaml".freeze
      LICENSE_FILE_FORMAT_VERSION = "4.0.0".freeze

      # License types list
      LICENSE_TYPES = {
        free: :free,
        trial: :trial,
        commercial: :commercial,
      }.freeze

      attr_reader :logger, :contents, :location
      attr_accessor :local_dir # Optional local path to use to seek

      def initialize(opts)
        @opts = opts
        @logger = ChefLicensing::Config.logger
        @contents_ivar = nil
        @location = nil

        @opts[:dir] ||= LicenseKeyFetcher::File.default_file_location
        @local_dir = @opts[:dir]
      end

      def fetch
        read_license_key_file
        contents&.key?(:licenses) ? fetch_license_keys(contents[:licenses]) : []
      end

      def fetch_license_keys(licenses)
        licenses.collect { |x| x[:license_key] }
      end

      def fetch_license_types
        read_license_key_file

        if contents.nil? || contents[:licenses].nil?
          []
        else
          contents[:licenses].collect { |x| x[:license_type] }
        end
      end

      def user_has_active_trial_license?
        @active_trial_status = false
        read_license_key_file

        if contents&.key?(:licenses)
          @active_trial_status = contents[:licenses].any? { |license| license[:license_type] == :trial && ChefLicensing.client(license_keys: [license[:license_key]]).active? }
        end
        @active_trial_status
      end

      def fetch_allowed_license_types_for_addition
        license_types = %i{free trial commercial}
        existing_license_types = fetch_license_types

        license_types -= [:trial] if existing_license_types.include? :trial
        license_types -= [:free] if existing_license_types.include?(:free) || user_has_active_trial_license?
        license_types.uniq
      end

      def fetch_license_keys_based_on_type(license_type)
        read_license_key_file
        if contents.nil?
          []
        else
          contents[:licenses].collect do |x|
            x[:license_key] if x[:license_type] == license_type
          end.compact
        end
      end

      # Writes a license_id file to disk in the location specified,
      # with the content given.
      # @return Array of Errors
      def persist(license_key, license_type = nil)
        raise LicenseKeyNotPersistedError.new("License type #{license_type} is not a valid license type.") unless LICENSE_TYPES[license_type.to_sym]

        license_data = {
          license_key: license_key,
          license_type: LICENSE_TYPES[license_type.to_sym],
          update_time: DateTime.now.to_s,
        }

        dir = @opts[:dir]
        license_key_file_path = "#{dir}/#{LICENSE_KEY_FILE}"
        create_license_directory_if_not_exist(dir, license_key_file_path)

        @contents = load_license_file(license_key_file_path)

        load_license_data_to_contents(license_data)
        write_license_file(license_key_file_path)
        []
      end

      # Returns true if a license_key file exists.
      def persisted?
        !!seek
      end

      def fetch_or_persist_url(license_server_url_from_config, license_server_url_from_system = nil)
        dir = @opts[:dir]
        license_key_file_path = "#{dir}/#{LICENSE_KEY_FILE}"
        create_license_directory_if_not_exist(dir, license_key_file_path)

        @contents = load_license_file(license_key_file_path)

        # Two possible cases:
        # 1. If contents is nil, load basic license data with the latest structure.
        # 2. If contents is not nil, but the license server URL in contents is different from the system's,
        #    update the license server URL in contents and licenses.yaml file.
        if @contents.nil?
          url = license_server_url_from_system || license_server_url_from_config
          load_basic_license_data_to_contents(url, [])
        elsif @contents && license_server_url_from_system && license_server_url_from_system != @contents[:license_server_url]
          @contents[:license_server_url] = license_server_url_from_system
        end

        # Ensure the license server URL is returned to the caller in all cases
        # (even if it's not persisted to the licenses.yaml file on the disk)
        begin
          write_license_file(license_key_file_path)
        rescue StandardError => e
          handle_error(e)
        ensure
          @license_server_url = @contents[:license_server_url]
        end
        logger.debug "License server URL: #{@license_server_url}"
        @license_server_url
      end

      def self.default_file_location
        ChefConfig::PathHelper.home(".chef")
      end

      def self.fetch_license_keys_based_on_type(license_type, opts = {})
        new(opts).fetch_license_keys_based_on_type(license_type)
      end

      def self.user_has_active_trial_license?(opts = {})
        new(opts).user_has_active_trial_license?
      end

      def self.fetch_or_persist_url(license_server_url_from_config, license_server_url_from_system = nil, opts = {})
        new(opts).fetch_or_persist_url(license_server_url_from_config, license_server_url_from_system)
      end

      private

      attr_accessor :license_server_url

      # Look for an *existing* license_id file in several locations.
      def seek
        return location if location

        on_windows = ChefConfig.windows?
        candidates = []

        # Include the user home directory ~/.chef
        candidates << "#{self.class.default_file_location}/#{LICENSE_KEY_FILE}"
        candidates << "/etc/chef/#{LICENSE_KEY_FILE}" unless on_windows

        # Include software installation dirs for bespoke downloads.
        # TODO: unlikely these would be writable if decision changes.
        [
          # TODO - get a complete list
          "chef-workstation",
          "inspec",
        ].each do |inst_dir|
          if on_windows
            candidates << "C:/opscode/#{inst_dir}/#{LICENSE_KEY_FILE}"
          else
            candidates << "/opt/#{inst_dir}/#{LICENSE_KEY_FILE}"
          end
        end

        # Include local directory if provided. Not usual, but useful for testing.
        candidates << "#{local_dir}/#{LICENSE_KEY_FILE}" if local_dir

        # Only picks up the first detected license file out of list of candidates
        @location = candidates.detect { |c| ::File.exist?(c) }
      end

      def working_directory
        (ChefConfig.windows? ? ENV["CD"] : ENV["PWD"]) || Dir.pwd
      end

      def read_license_key_file
        return contents if contents

        logger.debug "Reading license file from #{seek}"
        path = seek
        return nil unless path

        # only checking for major version for file format for breaking changes
        @contents ||= YAML.load(::File.read(path))

        # raise error if the file_format_version key is missing
        raise LicenseFileCorrupted.new("Unrecognized license file; :file_format_version missing.") unless @contents.key?(:file_format_version)

        # Three possible cases after loading the license file contents:
        # 1. If the file format version is the same as the current version (latest), verify the structure and return the contents.
        # 2. If the file format version is different but supported, migrate the contents to the current version and return them.
        # 3. If the file format version is different and not supported, raise an error.
        if major_version(@contents[:file_format_version]) == major_version(LICENSE_FILE_FORMAT_VERSION)
          current_version_class_name = get_license_file_class(LICENSE_FILE_FORMAT_VERSION)
          # we ignore any additional keys in the license file during verification
          raise LicenseFileCorrupted.new("Invalid data found in the license file.") unless current_version_class_name.send(:verify_structure, @contents)

          @contents
        elsif license_file_class_exists?(@contents[:file_format_version])
          @contents = migrate_license_file_content_to_current_version(@contents)
          write_license_file(path) # update the license file contents to the latest version
          @contents
        else
          logger.debug "License File version #{@contents[:file_format_version]} not supported."
          raise ChefLicensing::InvalidFileFormatVersion.new("Unable to read licenses. License File version #{@contents[:file_format_version]} not supported.")
        end
      end

      def major_version(version)
        Gem::Version.new(version).segments[0]
      end

      def create_license_directory_if_not_exist(dir, license_key_file_path)
        return if ::File.exist?(license_key_file_path)

        logger.debug "Creating directory for license_key file at #{dir}"
        msg = "Could not create directory for license_key file #{dir}"
        FileUtils.mkdir_p(dir)
      rescue StandardError => e
        handle_error(e, msg)
      end

      def load_license_file(license_key_file_path)
        return unless ::File.exist?(license_key_file_path)

        logger.debug "Reading license_key file at #{license_key_file_path}"
        msg = "Could not read license key file #{license_key_file_path}"
        YAML.load_file(license_key_file_path)
      rescue StandardError => e
        handle_error(e, msg)
      end

      def load_license_data_to_contents(license_data)
        return unless license_data

        logger.debug "Loading license data to contents"
        if @contents.nil? || @contents.empty? # this case is likely to happen only during testing
          load_basic_license_data_to_contents(@license_server_url, [license_data])
        elsif @contents[:licenses].nil?
          @contents[:licenses] = [license_data]
        elsif fetch_license_keys(@contents[:licenses])&.include?(license_data[:license_key])
          nil
        else
          @contents[:licenses] << license_data
        end
      end

      def write_license_file(license_key_file_path)
        logger.debug "Writing license_key file at #{license_key_file_path}"
        msg = "Could not write telemetry license_key file #{license_key_file_path}"
        ::File.write(license_key_file_path, YAML.dump(@contents))
      rescue StandardError => e
        handle_error(e, msg)
      end

      def handle_error(e, message = nil)
        logger.debug "#{e.backtrace.join("\n\t")}"
        e
      end

      # Returns the license file class for the given version.
      def get_license_file_class(version)
        Object.const_get("ChefLicensing::LicenseFile::V#{major_version(version)}")
      end

      # Returns true if the license file class for the given version exists.
      def license_file_class_exists?(version)
        Object.const_defined?("ChefLicensing::LicenseFile::V#{major_version(version)}")
      end

      # Loads the basic license data to contents in the current version's structure.
      def load_basic_license_data_to_contents(url, license_data = [])
        current_version_class_name = get_license_file_class(LICENSE_FILE_FORMAT_VERSION)
        @contents = current_version_class_name.send(:load_primary_structure)
        @contents[:file_format_version] = LICENSE_FILE_FORMAT_VERSION
        @contents[:license_server_url] = url || ""
        @contents[:licenses] = license_data
      end

      # Migrates the license file content to the current version and returns the migrated contents.
      def migrate_license_file_content_to_current_version(contents)
        logger.warn "License File version #{contents[:file_format_version]} is deprecated."
        logger.warn "Automatically migrating license file to version #{LICENSE_FILE_FORMAT_VERSION}."
        given_version_class_name = get_license_file_class(contents[:file_format_version])
        # we ignore any additional keys in the license file during verification
        raise LicenseFileCorrupted.new("Invalid data found in the license file.") unless given_version_class_name.send(:verify_structure, contents)

        current_version_class_name = get_license_file_class(LICENSE_FILE_FORMAT_VERSION)
        contents = current_version_class_name.send(:migrate_structure, contents, major_version(contents[:file_format_version]))
        contents
      end
    end
  end
end

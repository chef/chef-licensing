require "chef-config/windows"
require "chef-config/path_helper"
require "yaml"
require "date"
require "fileutils" unless defined?(FileUtils)
require_relative "../license_key_fetcher"
require_relative "../config"

module ChefLicensing
  class LicenseKeyFetcher

    # Represents a fethced license ID recorded on disk
    class File
      LICENSE_KEY_FILE = "licenses.yaml".freeze
      LICENSE_FILE_FORMAT_VERSION = "3.0.0".freeze

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
        license_keys = !contents.nil? && fetch_license_keys(contents[:licenses]) # list license keys
        license_keys || []
      end

      def fetch_license_keys(licenses)
        licenses.collect { |x| x[:license_key] }
      end

      def fetch_license_types
        read_license_key_file
        if contents.nil?
          []
        else
          contents[:licenses].collect { |x| x[:license_type] }
        end
      end

      def user_has_active_trial_license?
        return @active_trial_status if defined?(@active_trial_status)

        read_license_key_file
        if contents.nil?
          @active_trial_status = false
        else
          @active_trial_status = contents[:licenses].any? { |license| license[:license_type] == :trial && ChefLicensing.client(license_keys: [license[:license_key]]).active? }
        end
        @active_trial_status
      end

      def license_type_generation_options_based_on_file
        # TODO free license restrictions
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
        begin
          if ::File.exist?(license_key_file_path)
            msg = "Could not read license key file #{license_key_file_path}"
            current_keys = YAML.load_file(license_key_file_path)

            if current_keys && current_keys[:licenses]
              # Checking for unique keys
              unless fetch_license_keys(current_keys[:licenses]).include? license_key
                current_keys[:licenses].push(license_data)
                current_keys[:file_format_version] = LICENSE_FILE_FORMAT_VERSION
              end
              @contents = current_keys
            elsif !current_keys # if file is empty
              @contents = {
                licenses: [license_data] ,
                file_format_version: LICENSE_FILE_FORMAT_VERSION,
              }
            end
          else
            @contents = {
              licenses: [license_data] ,
              file_format_version: LICENSE_FILE_FORMAT_VERSION,
            }
            msg = "Could not create directory for license_key file #{dir}"
            FileUtils.mkdir_p(dir)
          end

          # write/overwrite license file content in the file
          msg = "Could not write telemetry license_key file #{license_key_file_path}"
          ::File.write(license_key_file_path, YAML.dump(@contents))
          []
        rescue StandardError => e
          logger.warn "#{msg}\n\t#{e.message}"
          logger.debug "#{e.backtrace.join("\n\t")}"
          [e]
        end
      end

      # Returns true if a license_key file exists.
      def persisted?
        !!seek
      end

      def self.default_file_location
        ChefConfig::PathHelper.home(".chef")
      end

      def self.fetch_license_keys_based_on_type(license_type, opts = {})
        new(opts).fetch_license_keys_based_on_type(license_type)
      end

      private

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

        path = seek
        return nil unless path

        # only checking for major version for file format for breaking changes
        @contents ||= YAML.load(::File.read(path))
        if major_version(@contents[:file_format_version]) == major_version(LICENSE_FILE_FORMAT_VERSION)
          @contents
        else
          raise LicenseKeyNotFetchedError.new("License File version #{@contents[:file_format_version]} not supported.")
        end
      end

      def major_version(version)
        Gem::Version.new(version).segments[0]
      end
    end
  end
end

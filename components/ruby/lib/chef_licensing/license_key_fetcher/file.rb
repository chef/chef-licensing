
require "chef-config/windows"
require "chef-config/path_helper"
require "yaml"
require "date"
require "fileutils"

module ChefLicensing
  class LicenseKeyFetcher

    # Represents a fethced license ID recorded on disk
    class File
      LICENSE_KEY_FILE = "license_key.yaml".freeze

      attr_reader :logger, :contents, :location
      attr_accessor :local_dir # Optional local path to use to seek

      def initialize(opts)
        @opts = opts
        @logger = opts[:logger]
        @contents_ivar = nil
        @location = nil

        @opts[:dir] ||= LicenseKeyFetcher::File.default_file_location
        @local_dir = @opts[:dir]

      end

      def fetch
        read_license_key_file
        !contents.nil? && contents[:license_key]
      end

      # Writes a license_id file to disk in the location specified,
      # with the content given.
      # @return Array of Errors
      def persist(license_key, _product, _version, content = {})
        content[:update_time] = DateTime.now.to_s
        content[:license_key] = license_key
        @contents = content
        dir = @opts[:dir]

        begin
          msg = "Could not create directory for license_key file #{dir}"
          FileUtils.mkdir_p(dir)
          msg = "Could not write telemetry license_key file #{dir}/#{LICENSE_KEY_FILE}"
          ::File.write("#{dir}/#{LICENSE_KEY_FILE}", YAML.dump(content))
          return []
        rescue StandardError => e
          logger.info "#{msg}\n\t#{e.message}"
          logger.debug "#{e.backtrace.join("\n\t")}"
          return [e]
        end
      end

      # Returns true if a license_key file exists.
      def persisted?
        !!seek
      end

      def self.default_file_location
        ChefConfig::PathHelper.home(".chef")
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

        @location = candidates.detect { |c| ::File.exist?(c) }
      end

      def working_directory
        (ChefConfig.windows? ? ENV["CD"] : ENV["PWD"]) || Dir.pwd
      end

      def read_license_key_file
        return contents if contents
        path = seek
        return nil unless path
        @contents ||= YAML.load(::File.read(path))
      end

    end
  end
end

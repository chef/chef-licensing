
require "chef-config/windows"
require "chef-config/path_helper"
require "yaml"
require "date"
require "fileutils" unless defined?(FileUtils)

module ChefLicensing
  class LicenseKeyFetcher

    # Represents a fethced license ID recorded on disk
    class File
      LICENSE_KEY_FILE = "license_key.yaml".freeze
      LICENSE_FILE_FORMAT_VERSION = "1.0.0".freeze

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
        !contents.nil? && fetch_license_keys(contents[:licenses]) # list license keys
      end

      def fetch_license_keys(licenses)
        licenses.collect{ |x| x[:license_key] }
      end

      # Writes a license_id file to disk in the location specified,
      # with the content given.
      # @return Array of Errors
      def persist(license_key, _product, _version)
        license_data = {
          license_key: license_key,
          update_time: DateTime.now.to_s
        }

        dir = @opts[:dir]
        license_key_file_path = "#{dir}/#{LICENSE_KEY_FILE}"
        begin
          if ::File.exist?(license_key_file_path)
            msg = "Could not read telemetry license_key file #{license_key_file_path}"
            current_keys = YAML.load_file(license_key_file_path)

            # Checking for unique keys
            if current_keys[:licenses]
              unless fetch_license_keys(current_keys[:licenses]).include? license_key
                current_keys[:licenses].push(license_data)
                current_keys[:file_format_version] = LICENSE_FILE_FORMAT_VERSION
              end
              @contents = current_keys
            elsif !current_keys # if file is empty
              @contents = {
                licenses: [license_data] ,
                file_format_version: LICENSE_FILE_FORMAT_VERSION
              }
            end
          else
            @contents = {
              licenses: [license_data] ,
              file_format_version: LICENSE_FILE_FORMAT_VERSION
            }
            msg = "Could not create directory for license_key file #{dir}"
            FileUtils.mkdir_p(dir)
          end

          # write/overwrite license file content in the file
          msg = "Could not write telemetry license_key file #{license_key_file_path}"
          ::File.write(license_key_file_path, YAML.dump(@contents))
          []
        rescue StandardError => e
          logger.info "#{msg}\n\t#{e.message}"
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
        if @contents[:file_format_version] == LICENSE_FILE_FORMAT_VERSION
          @contents
        else
          raise LicenseKeyNotFetchedError.new("License File version #{@contents[:version]} not supported.")
        end
      end
    end
  end
end

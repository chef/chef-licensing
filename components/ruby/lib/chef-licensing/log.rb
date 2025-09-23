require "mixlib/log"

module ChefLicensing
  class Log
    extend Mixlib::Log

    # Initialize with STDERR as the default output stream
    init(STDERR)
  end
end

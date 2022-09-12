require 'faraday'
module ChefLicensing
  module RestfulClient

    # Base class to handle all License Server endpoints
    class Base

    END_POINTS = {
      VALIDATE: 'validate',
      GENERATE_LICENSE: 'generate'
    }

    def validate(license)
      handle_connection do |connection|
        connection.get(END_POINTS[:validate], { license: license })
      end
    end

    def generate_license(payload)
      handle_connection do |connection|
        connection.post(END_POINTS[:GENERATE_LICENSE]) do |request|
          request.body = payload.to_json
        end
      end
    end

    def handle_connection
      # handle faraday errors
      yield connection
    rescue RestfulClientErrors
      # handle errors
    end

    private

    def connection
      Faraday.new(url: ChefLicensing::Config::LICENSING_SERVER) do |config|
        config.request = :json
        config.request :retry
        config.response :json, parser_options: { object_class: OpenStruct }
      end
    end
    end
  end
end
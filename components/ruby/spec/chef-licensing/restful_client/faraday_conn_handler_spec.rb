require "spec_helper"
require "chef-licensing/restful_client/faraday_conn_handler"

RSpec.describe ChefLicensing::RestfulClient::FaradayConnHandler do
  describe "#handle_connection" do
    let(:faraday_conn_handler) { described_class.new }
    let(:server_url) { "http://globalhost-license-server/License" }
    let(:endpoint) { "dummy_endpoint" }
    let(:post_endpoint) { "dummy_endpoint_2" }

    before do
      stub_request(:get, "#{server_url}/#{endpoint}")
        .with(query: {})
        .to_return(body: { data: true, message: "You have reached the server", status_code: 200 }.to_json,
                    headers: { content_type: "application/json" })
    end

    context "when request type is get" do
      it "fetches the response from the server" do
        expect(faraday_conn_handler.handle_connection(:get, server_url) do |conn|
          conn.get(endpoint)
        end).to be_truthy
      end
    end

    before do
      stub_request(:post, "#{server_url}/#{post_endpoint}")
        .with(body: {}.to_json)
        .to_return(body: {}.to_json,
                    headers: { content_type: "application/json" })
    end

    context "when request type is post" do
      it "sends a post request to the server" do
        expect(faraday_conn_handler.handle_connection(:post, server_url) do |conn|
          conn.post(post_endpoint) do |req|
            req.body = {}.to_json
            req.headers = { "Content-Type": "application/json" }
          end
        end).to be_truthy
      end
    end

    context "when request type is put" do
      it "raises Invalid request type error, since we do not support put" do
        expect {
          faraday_conn_handler.handle_connection(:put, server_url) do
            conn.put(endpoint)
          end
        }.to raise_error(ChefLicensing::RestfulClientError, "Invalid request type put")
      end
    end

    context "when request type is delete" do
      it "raises Invalid request type error, since we do not support delete" do
        expect {
          faraday_conn_handler.handle_connection(:delete, server_url) do
            conn.delete(endpoint)
          end
        }.to raise_error(ChefLicensing::RestfulClientError, "Invalid request type delete")
      end
    end
  end
end

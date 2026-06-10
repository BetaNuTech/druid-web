require 'rails_helper'
require 'socket'

RSpec.describe Yardi::Voyager::Api::Base do
  let(:api) { described_class.new(double('configuration')) }

  # Runs a one-shot HTTP server on a local socket so requests exercise the
  # real HTTParty/Net::HTTP stack. Yields the port and a hash that captures
  # the request line, headers, and body the server received.
  def with_local_http_server(response_body: '<soap>ok</soap>')
    received = {}
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    thread = Thread.new do
      client = server.accept
      received[:request_line] = client.gets
      headers = {}
      while (line = client.gets) && line != "\r\n"
        key, value = line.split(': ', 2)
        headers[key.downcase] = value.to_s.strip
      end
      received[:headers] = headers
      if headers['content-length']
        received[:body] = client.read(headers['content-length'].to_i)
      end
      client.write("HTTP/1.1 200 OK\r\n" \
                   "Content-Type: text/xml\r\n" \
                   "Content-Length: #{response_body.bytesize}\r\n" \
                   "Connection: close\r\n\r\n#{response_body}")
      client.close
    end
    yield port, received
  ensure
    thread&.kill
    server&.close
  end

  describe '#fetch_data' do
    it 'POSTs the body and headers and returns the parsed response' do
      with_local_http_server do |port, received|
        result = api.fetch_data(
          url: "http://127.0.0.1:#{port}/Webservices/ItfILSGuestCard.asmx",
          body: '<soap:Envelope>request</soap:Envelope>',
          headers: {
            'Content-Type' => 'text/xml; charset=utf-8',
            'SOAPAction' => 'http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard/GetYardiGuestActivity_Login'
          }
        )

        expect(result.code).to eq(200)
        expect(result.body).to eq('<soap>ok</soap>')

        expect(received[:request_line]).to start_with('POST /Webservices/ItfILSGuestCard.asmx')
        expect(received[:headers]['content-type']).to eq('text/xml; charset=utf-8')
        expect(received[:headers]['soapaction']).
          to eq('http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard/GetYardiGuestActivity_Login')
        expect(received[:body]).to eq('<soap:Envelope>request</soap:Envelope>')
      end
    end

    it 'retries on Net::ReadTimeout and returns data on a subsequent success' do
      allow(api).to receive(:sleep)
      attempts = 0
      response = double('response', code: 200)
      allow(HTTParty).to receive(:post) do
        attempts += 1
        raise Net::ReadTimeout if attempts < 3

        response
      end

      result = api.fetch_data(url: 'http://example.test/', body: '', headers: {})

      expect(result).to eq(response)
      expect(attempts).to eq(3)
    end

    it 'gives up after 3 retries, notifies, and re-raises' do
      allow(api).to receive(:sleep)
      allow(HTTParty).to receive(:post).and_raise(Net::ReadTimeout)
      expect(ErrorNotification).to receive(:send)

      expect {
        api.fetch_data(url: 'http://example.test/', body: '', headers: {})
      }.to raise_error(Net::ReadTimeout)
    end
  end

  describe 'basic auth GET requests' do
    # Covers the HTTParty.get(url, basic_auth: ...) pattern used by
    # Messages::DeliveryAdapters::Cloudmailin::Health#fetch_status
    it 'sends an Authorization header from basic_auth credentials' do
      with_local_http_server(response_body: '[]') do |port, received|
        result = HTTParty.get(
          "http://127.0.0.1:#{port}/status",
          basic_auth: { username: 'apiuser', password: 'apisecret' }
        )

        expect(result.code).to eq(200)
        expect(received[:request_line]).to start_with('GET /status')
        credentials = Base64.strict_encode64('apiuser:apisecret')
        expect(received[:headers]['authorization']).to eq("Basic #{credentials}")
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Yardi::Backup::SocksTunnel do
  describe '.parse' do
    it 'reads user:pass@host:port' do
      proxy = described_class.parse('fixie:secret@speedway.usefixie.com:1080')
      expect(proxy.to_h).to include(host: 'speedway.usefixie.com', port: 1080, user: 'fixie', password: 'secret')
    end

    it 'accepts a socks5:// prefix and keeps a password containing a colon' do
      proxy = described_class.parse('socks5://fixie:p:ss@10.0.0.1:1080')
      expect(proxy.to_h).to include(host: '10.0.0.1', port: 1080, user: 'fixie', password: 'p:ss')
    end

    it 'accepts a bare host:port' do
      expect(described_class.parse('proxy.local:1080').to_h).to include(host: 'proxy.local', port: 1080, user: nil)
    end

    it 'rejects a value without a port' do
      expect { described_class.parse('fixie:secret@proxy.local') }.to raise_error(ArgumentError, /missing a port/)
    end
  end

  describe '.from_env' do
    it 'prefers YARDI_SOCKS_PROXY, falls back to FIXIE_SOCKS_HOST, and is nil when neither is set' do
      expect(described_class.from_env('YARDI_SOCKS_PROXY' => 'a:1', 'FIXIE_SOCKS_HOST' => 'b:2').host).to eq('a')
      expect(described_class.from_env('FIXIE_SOCKS_HOST' => 'b:2').source).to eq('FIXIE_SOCKS_HOST')
      expect(described_class.from_env({})).to be_nil
    end
  end

  describe 'relaying through a SOCKS5 proxy' do
    let(:echo_server) { TCPServer.new('127.0.0.1', 0) }
    let(:proxy_server) { TCPServer.new('127.0.0.1', 0) }
    let(:connect_requests) { Queue.new }
    let(:threads) { [] }

    after do
      threads.each(&:kill)
      [echo_server, proxy_server].each { |server| server.close rescue nil }
    end

    def serve_echo
      threads << Thread.new do
        loop do
          client = echo_server.accept
          Thread.new(client) { |c| while (line = c.gets) do c.write(line) end }
        end
      end
    end

    # Minimal RFC 1928/1929 proxy: optional user/password auth, then CONNECT
    def serve_proxy(user: nil, password: nil)
      threads << Thread.new do
        loop do
          client = proxy_server.accept
          Thread.new(client) do |c|
            _version, method_count = c.read(2).unpack('CC')
            c.read(method_count)
            if user
              c.write([5, 2].pack('CC'))
              _auth_version, user_length = c.read(2).unpack('CC')
              given_user = c.read(user_length)
              given_password = c.read(c.read(1).unpack1('C'))
              accepted = given_user == user && given_password == password
              c.write([1, accepted ? 0 : 1].pack('CC'))
              next c.close unless accepted
            else
              c.write([5, 0].pack('CC'))
            end
            _version, _command, _reserved, address_type = c.read(4).unpack('C4')
            host = address_type == 1 ? IPAddr.ntop(c.read(4)) : c.read(c.read(1).unpack1('C'))
            port = c.read(2).unpack1('n')
            connect_requests << [host, port]
            upstream = TCPSocket.new(host, port)
            c.write([5, 0, 0, 1, 0, 0, 0, 0, 0, 0].pack('C*'))
            [Thread.new { IO.copy_stream(c, upstream) rescue nil },
             Thread.new { IO.copy_stream(upstream, c) rescue nil }].each(&:join)
          end
        end
      end
    end

    def round_trip(proxy)
      tunnel = described_class.new(proxy: proxy, target_host: '127.0.0.1', target_port: echo_server.addr[1]).open
      socket = TCPSocket.new('127.0.0.1', tunnel.local_port)
      socket.write("ping\n")
      Timeout.timeout(5) { socket.gets }
    ensure
      socket&.close
      tunnel&.close
    end

    it 'carries bytes both ways through an authenticating proxy' do
      serve_echo
      serve_proxy(user: 'fixie', password: 'secret')
      proxy = described_class::Proxy.new(host: '127.0.0.1', port: proxy_server.addr[1], user: 'fixie', password: 'secret')

      expect(round_trip(proxy)).to eq("ping\n")
      expect(connect_requests.pop).to eq(['127.0.0.1', echo_server.addr[1]])
    end

    it 'works with a proxy that needs no credentials' do
      serve_echo
      serve_proxy
      proxy = described_class::Proxy.new(host: '127.0.0.1', port: proxy_server.addr[1])

      expect(round_trip(proxy)).to eq("ping\n")
    end

    it 'drops the connection when the proxy rejects the credentials' do
      serve_echo
      serve_proxy(user: 'fixie', password: 'secret')
      proxy = described_class::Proxy.new(host: '127.0.0.1', port: proxy_server.addr[1], user: 'fixie', password: 'wrong')
      tunnel = described_class.new(proxy: proxy, target_host: '127.0.0.1', target_port: echo_server.addr[1]).open
      socket = TCPSocket.new('127.0.0.1', tunnel.local_port)
      socket.write("ping\n")

      expect(IO.select([socket], nil, nil, 5)).not_to be_nil
      outcome = begin
        socket.gets
      rescue Errno::ECONNRESET
        :reset
      end
      expect(outcome).to be_nil.or eq(:reset)
    ensure
      socket&.close
      tunnel&.close
    end
  end
end

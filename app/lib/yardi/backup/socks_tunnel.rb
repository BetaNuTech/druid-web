require 'socket'
require 'ipaddr'
require 'io/wait'

module Yardi
  module Backup
    # A local TCP port forwarded to the Yardi backup database through a
    # SOCKS5 proxy (Fixie Socks on Heroku).
    #
    # The backup server's firewall only admits the proxy's two static IPs, and
    # Heroku dynos have no stable outbound IP. FreeTDS (tiny_tds) cannot speak
    # SOCKS itself, so Yardi::Backup::Database points it at this tunnel's
    # local port instead; each accepted connection is relayed through the
    # proxy. TLS inside the TDS stream passes through untouched.
    #
    # The relay runs in a forked child process: tiny_tds holds Ruby's global
    # VM lock while it logs in, so relay threads in the same process would
    # never run and the login would time out.
    #
    # Same settings as Cobalt2's db/connection.ts: YARDI_SOCKS_PROXY, or the
    # Fixie add-on's own FIXIE_SOCKS_HOST.
    class SocksTunnel
      PROXY_ENV = %w[YARDI_SOCKS_PROXY FIXIE_SOCKS_HOST].freeze
      TIMEOUT = 15 # seconds, for the proxy handshake

      class Error < StandardError; end

      Proxy = Struct.new(:host, :port, :user, :password, :source, keyword_init: true)

      # Accepts `user:pass@host:port`, `socks5://user:pass@host:port` or a bare
      # `host:port`. Splits on the LAST `@` and the FIRST `:` of the
      # credentials, so a password containing `:` survives.
      def self.parse(raw, source: PROXY_ENV.first)
        value = raw.to_s.strip.sub(%r{\Asocks5h?://}i, '')
        at = value.rindex('@')
        auth = at ? value[0...at] : ''
        host_part = at ? value[(at + 1)..] : value

        colon = host_part.rindex(':')
        raise ArgumentError, "#{source} is missing a port: expected user:pass@host:port" unless colon

        host = host_part[0...colon]
        port = Integer(host_part[(colon + 1)..], exception: false)
        raise ArgumentError, "#{source} has an unparseable host:port" unless host.present? && port&.between?(1, 65_535)

        user, password = auth.split(':', 2) if auth.present?
        Proxy.new(host: host, port: port, user: user, password: password, source: source)
      end

      # The configured proxy, or nil when none is set (direct connection).
      def self.from_env(env = ENV)
        PROXY_ENV.each do |name|
          return parse(env[name], source: name) if env[name].present?
        end
        nil
      end

      attr_reader :local_port

      def initialize(proxy:, target_host:, target_port:)
        @proxy = proxy
        @target_host = target_host
        @target_port = Integer(target_port)
      end

      def open
        server = TCPServer.new('127.0.0.1', 0)
        @local_port = server.addr[1]
        parent_pid = Process.pid
        @pid = fork do
          trap('TERM') { exit!(0) }
          # Never outlive the process that opened the tunnel
          Thread.new do
            loop do
              exit!(0) if Process.ppid != parent_pid
              sleep 1
            end
          end
          begin
            accept_loop(server)
          ensure
            exit!(0)
          end
        end
        server.close
        self
      end

      def close
        return unless @pid

        Process.kill('TERM', @pid)
        Process.wait(@pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      ensure
        @pid = nil
      end

      private

      def accept_loop(server)
        loop do
          client = server.accept
          Thread.new(client) { |socket| relay(socket) }
        end
      end

      def relay(client)
        upstream = connect_through_proxy
        copiers = [
          Thread.new { copy(client, upstream) },
          Thread.new { copy(upstream, client) }
        ]
        copiers.each(&:join)
      rescue StandardError => e
        # stderr, not Rails.logger: this runs in the forked child, which can
        # inherit a logger lock held by another thread at fork time.
        warn("Yardi::Backup::SocksTunnel: #{e.class}: #{e.message}")
      ensure
        [client, upstream].compact.each { |socket| close_quietly(socket) }
      end

      def copy(from, to)
        IO.copy_stream(from, to)
      rescue IOError, SystemCallError
        nil
      ensure
        begin
          to.close_write
        rescue IOError, SystemCallError
          nil
        end
      end

      def close_quietly(socket)
        socket.close
      rescue IOError, SystemCallError
        nil
      end

      # RFC 1928 CONNECT, with RFC 1929 username/password auth when configured.
      def connect_through_proxy
        socket = Socket.tcp(@proxy.host, @proxy.port, connect_timeout: TIMEOUT)

        auth_methods = @proxy.user.present? ? [0x00, 0x02] : [0x00]
        socket.write([0x05, auth_methods.size, *auth_methods].pack('C*'))
        version, method = read_exactly(socket, 2).unpack('CC')
        raise Error, "SOCKS5 proxy replied with protocol version #{version}" unless version == 0x05

        case method
        when 0x00
          nil
        when 0x02
          user = @proxy.user.to_s.b
          password = @proxy.password.to_s.b
          socket.write([0x01, user.bytesize].pack('CC') + user + [password.bytesize].pack('C') + password)
          _auth_version, status = read_exactly(socket, 2).unpack('CC')
          raise Error, 'SOCKS5 proxy rejected the credentials' unless status == 0x00
        else
          raise Error, 'SOCKS5 proxy offered no acceptable authentication method'
        end

        socket.write([0x05, 0x01, 0x00].pack('C*') + address_bytes + [@target_port].pack('n'))
        version, reply, _reserved, address_type = read_exactly(socket, 4).unpack('C4')
        unless version == 0x05 && reply == 0x00
          raise Error, "SOCKS5 CONNECT to #{@target_host}:#{@target_port} failed (reply #{reply})"
        end

        # Discard the bound address the proxy reports back
        case address_type
        when 0x01 then read_exactly(socket, 4 + 2)
        when 0x03 then read_exactly(socket, read_exactly(socket, 1).unpack1('C') + 2)
        when 0x04 then read_exactly(socket, 16 + 2)
        end
        socket
      rescue StandardError
        close_quietly(socket) if socket
        raise
      end

      def address_bytes
        ip = begin
          IPAddr.new(@target_host)
        rescue IPAddr::InvalidAddressError
          nil
        end
        if ip&.ipv4?
          [0x01].pack('C') + ip.hton
        elsif ip&.ipv6?
          [0x04].pack('C') + ip.hton
        else
          [0x03, @target_host.bytesize].pack('CC') + @target_host.b
        end
      end

      def read_exactly(socket, length)
        buffer = +''.b
        while buffer.bytesize < length
          raise Error, 'SOCKS5 proxy timed out' unless socket.wait_readable(TIMEOUT)

          buffer << socket.readpartial(length - buffer.bytesize)
        end
        buffer
      end
    end
  end
end

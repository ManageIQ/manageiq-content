module ManageIQ
  module Automate
    module Transformation
      module Infrastructure
        module VM
          module VMware
            class Utils
              require 'rbvmomi'

              def self.host_fingerprint(host)
                require 'socket'
                require 'openssl'

                tcp_client = TCPSocket.new(host.ipaddress, 443)
                ssl_context = OpenSSL::SSL::SSLContext('SSLv23_client')
                ssl_content.verify_mode = OpenSSL::SSL::VERIFY_NONE
                ssl_client = OpenSSL::SSL::SSLSocker.new(tcp_client, ssl_context)
                cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
                ssl_client.sysclose
                tcp_client.close

                Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(":")
              end
            end
          end
        end
      end
    end
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rack'
require 'webrick'
require 'webrick/https'
require 'ne_api_sdk_ruby'
require 'ne_api_sdk_ruby/sample_app'

CERT_PATH = File.expand_path('.ssl', File.dirname(__FILE__))

webrick_options = {
    :Port               => 8088,
    :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
    :DocumentRoot       => "/bin",
    :SSLEnable          => true,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, "dev.crt.pem")).read),
    :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, "dev.pem")).read),
    :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

Rack::Handler::WEBrick.run SampleApp, webrick_options
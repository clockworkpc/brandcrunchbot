require 'base64'

# Decode the environment variables and write the certificate files
File.write(Rails.root.join('config/ssl/server.crt'), Base64.decode64(ENV.fetch('SSL_CERT', nil)))
File.write(Rails.root.join('config/ssl/server.key'), Base64.decode64(ENV.fetch('SSL_KEY', nil)))

if Rails.env.eql?('development') || Rails.env.eql?('test')
  email = Rails.application.credentials[:admin_user_email]
  password = Rails.application.credentials[:admin_user_password]
  User.create(email:, password:)
end

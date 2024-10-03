alex_email = Rails.application.credentials[:user_alex_email]
alex_password = Rails.application.credentials[:user_alex_password]
markus_email = Rails.application.credentials[:user_markus_email]
markus_password = Rails.application.credentials[:user_markus_password]

User.create(email: alex_email, password: alex_password)
User.create(email: markus_email, password: markus_password)

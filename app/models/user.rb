class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  after_create :authorize_user, :send_welcome_email

  def authorize_user
    authorised_users = JSON.parse(File.read('config/authorized_users.json'))
    is_whitelisted = authorised_users.include?(email)
    current_authorized = authorized || false  # Treat nil as false
    return if is_whitelisted == current_authorized
    self.authorized = is_whitelisted
    save
  end  

  def send_welcome_email
    return unless authorized?  # Only send email if user is authorized
    UserMailer.welcome_email(self).deliver_now
  end
end

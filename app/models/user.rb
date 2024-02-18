class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  after_create :authorize_user, :send_welcome_email

  def authorize_user
    authorised_users = JSON.parse(File.read('config/allmoxy/authorized_users.json'))
    is_whitelisted = authorised_users.include?(email)

    return if is_whitelisted == authorized?

    self.authorized = is_whitelisted
    save
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_now
  end
end

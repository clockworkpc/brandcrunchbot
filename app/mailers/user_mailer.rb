class UserMailer < ApplicationMailer
  default from: 'officerobot@panhandledoor.com'

  def welcome_email(user, explicit_password = nil)
    @explicit_password = explicit_password
    @user = user
    @url = 'https://panhandledoor.com'
    mail(to: @user.email, subject: 'Welcome to the Office Robot') # rubocop:disable Rails/I18nLocaleTexts
  end
end

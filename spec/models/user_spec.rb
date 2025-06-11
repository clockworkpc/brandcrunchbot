require 'rails_helper'

RSpec.describe User, type: :model do
  # Clean up users before each test to avoid conflicts
  before(:each) do
    User.delete_all
  end
  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end
  end

  describe 'callbacks' do
    it 'calls authorize_user after create' do
      user = build(:user)
      expect(user).to receive(:authorize_user)
      user.save
    end

    it 'calls send_welcome_email after create' do
      user = build(:user)
      expect(user).to receive(:send_welcome_email)
      user.save
    end
  end

  describe '#authorize_user' do
    let(:authorized_users_data) { ['authorized@example.com', 'admin@example.com'] }
    let(:user) { build(:user, email: 'test@example.com', authorized: nil) }

    before do
      allow(File).to receive(:read).with('config/authorized_users.json')
                                   .and_return(authorized_users_data.to_json)
    end

    context 'when user email is in authorized users list' do
      let(:user) { build(:user, email: 'authorized@example.com', authorized: nil) }

      it 'sets authorized to true' do
        user.save
        expect(user.authorized).to be true
      end

      it 'saves the user' do
        expect(user).to receive(:save).and_call_original
        user.send(:authorize_user)
      end
    end

    context 'when user email is not in authorized users list' do
      let(:user) { build(:user, email: 'unauthorized@example.com', authorized: false) }

      it 'sets authorized to false' do
        user.save
        expect(user.authorized).to be false
      end
    end

    context 'when user authorization status matches whitelist status' do
      let(:user) { build(:user, email: 'authorized@example.com', authorized: true) }

      it 'does not change authorized status' do
        expect(user).not_to receive(:save)
        user.send(:authorize_user)
        expect(user.authorized).to be true
      end
    end

    context 'when authorized users file cannot be read' do
      before do
        allow(File).to receive(:read).with('config/authorized_users.json')
                                     .and_raise(Errno::ENOENT)
      end

      it 'raises an error' do
        expect { user.save }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when authorized users file contains invalid JSON' do
      before do
        allow(File).to receive(:read).with('config/authorized_users.json')
                                     .and_return('invalid json')
      end

      it 'raises JSON parse error' do
        expect { user.save }.to raise_error(JSON::ParserError)
      end
    end

    context 'when authorized users file is empty array' do
      before do
        allow(File).to receive(:read).with('config/authorized_users.json')
                                     .and_return('[]')
      end

      let(:user) { build(:user, email: 'test@example.com', authorized: true) }

      it 'sets authorized to false' do
        user.save
        expect(user.authorized).to be false
      end
    end
  end

  describe '#send_welcome_email' do
    let(:user) { build(:user, authorized: true) }
    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(UserMailer).to receive(:welcome_email).and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_now)
    end

    context 'when user is authorized' do
      it 'calls UserMailer.welcome_email with user' do
        user.send(:send_welcome_email)
        expect(UserMailer).to have_received(:welcome_email).with(user)
      end

      it 'delivers the email immediately' do
        user.send(:send_welcome_email)
        expect(mailer_double).to have_received(:deliver_now)
      end
    end

    context 'when user is not authorized' do
      let(:user) { build(:user, authorized: false) }

      it 'does not send welcome email' do
        user.send(:send_welcome_email)
        expect(UserMailer).not_to have_received(:welcome_email)
      end
    end

    context 'when user authorization is nil' do
      let(:user) { build(:user, authorized: nil) }

      it 'does not send welcome email' do
        user.send(:send_welcome_email)
        expect(UserMailer).not_to have_received(:welcome_email)
      end
    end

    context 'when email delivery fails' do
      before do
        allow(mailer_double).to receive(:deliver_now).and_raise(StandardError.new('Email delivery failed'))
      end

      it 'raises the error' do
        expect { user.send(:send_welcome_email) }.to raise_error(StandardError, 'Email delivery failed')
      end
    end
  end

  describe 'integration test for user creation' do
    let(:authorized_users_data) { ['authorized@example.com'] }
    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(File).to receive(:read).with('config/authorized_users.json')
                                   .and_return(authorized_users_data.to_json)
      allow(UserMailer).to receive(:welcome_email).and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_now)
    end

    context 'creating an authorized user' do
      let(:user_params) do
        {
          email: 'authorized@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end

      it 'creates user, authorizes them, and sends welcome email' do
        user = User.create!(user_params)
        
        expect(user.authorized).to be true
        expect(UserMailer).to have_received(:welcome_email).with(user)
        expect(mailer_double).to have_received(:deliver_now)
      end
    end

    context 'creating an unauthorized user' do
      let(:user_params) do
        {
          email: 'unauthorized@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end

      it 'creates user, does not authorize them, and does not send welcome email' do
        user = User.create!(user_params)
        
        expect(user.authorized).to be_falsy  # Could be false or nil
        expect(UserMailer).not_to have_received(:welcome_email)
        expect(mailer_double).not_to have_received(:deliver_now)
      end
    end
  end

  describe 'database attributes' do
    it 'has an authorized attribute' do
      user = User.new
      expect(user).to respond_to(:authorized)
      expect(user).to respond_to(:authorized=)
    end
  end

  describe 'validations' do
    before do
      # Clean up any existing users to avoid uniqueness conflicts
      User.delete_all
    end

    it 'validates presence of email' do
      user = User.new(password: 'password123')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'validates uniqueness of email' do
      create(:user, email: 'unique@example.com')
      user = build(:user, email: 'unique@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end

    it 'validates email format' do
      user = build(:user, email: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'validates password presence' do
      user = User.new(email: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'validates password minimum length' do
      user = build(:user, password: '12345')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end
  end
end

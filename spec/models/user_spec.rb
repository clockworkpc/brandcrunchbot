require 'rails_helper'

RSpec.describe User, type: :model do
  let(:authorized_users) { JSON.parse(File.read('config/allmoxy/authorized_users.json')) }

  let(:email) { authorized_users.sample }

  it 'is not authorized' do
    user1 = create(:user)
    expect(user1.authorized?).to be(false)
  end

  it 'is authorized' do
    user2 = create(:user, email:)
    puts email
    expect(user2.authorized?).to be(true)
  end
end

class Auction < ApplicationRecord
  enum :purchase_status, {
    pending: 'pending',
    purchased: 'purchased',
    failed: 'failed',
    rescheduled: 'rescheduled',
    not_found: 'not_found'
  }
end

namespace :godaddy do
  desc 'Get Auction Details by Domain Name'
  task domain_name_info: :environment do
    service = GodaddyApi.new
    domain_name = 'maby.com'
    service.get_auction_details(domain_name:)
  end
end

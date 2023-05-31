class AllmoxyConfigService
  def import_companies_from_csv(csv_path)
    doc = CSV.table(csv_path)
    doc.each do |row|
      Customer.find_or_create_by(
        allmoxy_id: row[:company_id],
        customer_name: row[:name]
      )
    end
  end

  def import_individuals_from_csv(csv_path)
    doc = CSV.table(csv_path)
    doc.each do |row|
      allmoxy_id = row[:contact_id]
      customer_name = row[:name]

      Customer.find_or_create_by(
        allmoxy_id:,
        customer_name:
      )
    end
  end

  def import_products_from_csv(csv_path)
    doc = CSV.table(csv_path)
    doc.each do |row|
      product_id = row[:id]
      product_name = row[:product_name]

      Product.find_or_create_by(
        product_id:,
        product_name:
      )
    end
  end
end

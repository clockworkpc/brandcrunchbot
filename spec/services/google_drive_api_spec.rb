require 'rails_helper'

RSpec.describe GoogleDriveApi do
  let(:folder_path) { 'tmp/product_attributes/product_attributes-2022-09-13' }
  let(:upload_source) do
    'tmp/product_attributes/product_attributes-2022-09-13/product_attribute_selectors-379-2022-09-13T08:27:34-07:00.csv'
  end
  let(:parent_folder_id) { '1PvcFM7VH4k5fpkV9QSxOly2kmV6wSmOF' }
  let(:product_attribute_selections_folder_id) { '1X3wIJupUoyifH61IE90Tnz3ae1QNP0FV' }
  let(:team_drive_id) { '0AOjzUAFRsFyVUk9PVA' }

  describe 'Listing subfolders' do
    it 'lists subfolders for Salvador_Files' do
      gda = described_class.new
      res = gda.empty_subfolders('Salvador_Files')
      puts res
    end
  end

  describe 'File Creation' do
    before do
      @gda = described_class.new
    end

    it 'creates a folder', focus: false do
      @gda.create_folder(
        parent_folder_id:,
        folder_path:
      )
    end

    it 'uploads to a folder', focus: false do
      @gda.upload_to_folder(
        parent_folder_id:,
        fields: 'id, name',
        upload_source:
      )
    end

    it 'uploads a folder and its contents', focus: false do
      @gda.upload_folder(
        parent_folder_id: product_attribute_selections_folder_id,
        folder_path:,
        team_drive_id:
      )
    end
  end
end

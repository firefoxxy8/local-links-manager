require 'rails_helper'

RSpec.describe LinksController, type: :controller do
  before do
    login_as_stub_user
    @local_authority = create(:local_authority)
    @service = create(:service)
    @interaction = create(:interaction)
  end

  describe 'GET edit' do
    it 'retrieves HTTP success' do
      get :edit, params: { local_authority_slug: @local_authority.slug, service_slug: @service.slug, interaction_slug: @interaction.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET homepage_links_status_csv' do
    it "retrieves HTTP success" do
      get :homepage_links_status_csv
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to eq('text/csv')
    end
  end

  describe 'GET links_status_csv' do
    it "retrieves HTTP success" do
      get :links_status_csv
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to eq('text/csv')
    end
  end

  describe 'GET bad_links_url_and_status_csv' do
    it "retrieves HTTP success" do
      get :bad_links_url_and_status_csv
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to eq('text/csv')
    end
  end
end

require 'rails_helper'

RSpec.describe Link, type: :model do
  describe 'validations' do
    subject(:link) { create(:link) }

    it { is_expected.to validate_presence_of(:local_authority) }
    it { is_expected.to validate_presence_of(:service_interaction) }
    it { is_expected.to validate_uniqueness_of(:service_interaction_id).scoped_to(:local_authority_id) }

    describe '#url' do
      it 'disallows urls without schemes' do
        is_expected.not_to allow_value('example.com').for(:url).with_message('is not a URL')
      end

      it 'disallows urls without a domain' do
        is_expected.not_to allow_value('com').for(:url).with_message('is not a URL')
      end

      it 'allows http urls' do
        is_expected.to allow_value('http://example.com').for(:url)
      end

      it 'allows https urls' do
        is_expected.to allow_value('https://example.com').for(:url)
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:local_authority) }
    it { is_expected.to belong_to(:service_interaction) }

    it { is_expected.to have_one(:service).through(:service_interaction) }
    it { is_expected.to have_one(:interaction).through(:service_interaction) }
  end

  describe '.broken_or_missing' do
    it 'fetches broken and missing links' do
      link1 = create(:missing_link)
      link2 = create(:link, status: "broken")
      create(:link)

      expect(Link.broken_or_missing).to match_array([link1, link2])
    end
  end

  describe '.for_service' do
    it 'fetches all the links for the supplied service' do
      service1 = create(:service, label: 'Service 1', lgsl_code: 1)
      service2 = create(:service, label: 'Service 2', lgsl_code: 2)

      interaction1 = create(:interaction, label: 'Interaction 1', lgil_code: 1)
      interaction2 = create(:interaction, label: 'Interaction 2', lgil_code: 2)

      service1_interaction1 = create(:service_interaction, service: service1, interaction: interaction1)
      service1_interaction2 = create(:service_interaction, service: service1, interaction: interaction2)
      service2_interaction2 = create(:service_interaction, service: service2, interaction: interaction1)

      local_authority1 = create(:local_authority, name: 'Aberdeen', gss: 'S100000001', snac: '00AB1')
      local_authority2 = create(:local_authority, name: 'Aberdeenshire', gss: 'S100000002', snac: '00AB2')

      link1 = create(:link, local_authority: local_authority1, service_interaction: service1_interaction1)
      link2 = create(:link, local_authority: local_authority1, service_interaction: service1_interaction2)
      create(:link, local_authority: local_authority1, service_interaction: service2_interaction2)
      link4 = create(:link, local_authority: local_authority2, service_interaction: service1_interaction1)

      expect(Link.for_service(service1)).to match_array([link1, link2, link4])
    end

    context 'to avoid n+1 queries' do
      let(:service) { create(:service) }

      before do
        interaction = create(:interaction)
        service_interaction = create(:service_interaction, service: service, interaction: interaction)
        local_authority = create(:local_authority)
        create(:link, local_authority: local_authority, service_interaction: service_interaction)
      end

      subject(:links) { Link.for_service(service) }

      it 'preloads the service interaction on the fetched records' do
        expect(links.first.association(:service_interaction)).to be_loaded
      end

      it 'preloads the service of the service interaction on the fetched records' do
        expect(links.first.service_interaction.association(:service)).to be_loaded
      end

      it 'preloads the interaction of the service interaction on the fetched records' do
        expect(links.first.service_interaction.association(:interaction)).to be_loaded
      end
    end
  end

  describe '.retrieve' do
    let!(:service1) { create(:service, label: 'Service 1', lgsl_code: 1) }

    let!(:interaction1) { create(:interaction, label: 'Interaction 1', lgil_code: 1) }

    let!(:service1_interaction1) { create(:service_interaction, service: service1, interaction: interaction1) }

    let!(:local_authority1) { create(:local_authority, name: 'Aberdeen', gss: 'S100000001', snac: '00AB1') }

    let!(:expected_link) { create(:link, local_authority: local_authority1, service_interaction: service1_interaction1) }

    let(:params) {
      {
        local_authority_slug: local_authority1.slug,
        service_slug: service1.slug,
        interaction_slug: interaction1.slug
      }
    }

    subject(:link) { Link.retrieve(params) }

    it 'fetches the correct link for the service' do
      expect(link.url).to eq(expected_link.url)
    end
  end

  describe "#make_missing" do
    it "makes a link into a missing link" do
      link = create(:link, url: "https://www.gov.uk", status: "ok", analytics: 73)

      link.make_missing
      link.reload

      expect(link.url).to be_nil
      expect(link.status).to eq("missing")
      expect(link.analytics).to eq(73)
    end
  end

  describe "before_update" do
    before do
      @problem_summary = "Invalid URL"
      @errors = ["No host is given in the URL."]
      @warnings = ["Check it's ok for these to be public."]
    end

    it "sets the link status, last checked time, errors and warnings to nil if the link is updated and does not already exist" do
      @link = create(:link, status: "ok", link_last_checked: Time.now)
      @link.url = "http://example.com"
      @link.save!
      expect(@link.status).to be_nil
      expect(@link.link_last_checked).to be_nil
      expect(@link.link_errors).to be_empty
      expect(@link.link_warnings).to be_empty
    end

    it "sets the link status, last checked time and link errors to an existing url's status, last checked time and link errors" do
      time = Timecop.freeze("2016-07-14 11:34:09 +0100")
      @link1 = create(:link, url: "http://example.com/thing", status: "ok", link_last_checked: Time.now)
      @link2 = create(:link, url: "http://example.com", status: "ok", link_last_checked: time, problem_summary: @problem_summary, link_errors: @errors)
      @link1.url = "http://example.com"
      @link1.save!
      expect(@link1.status).to eq(@link2.status)
      expect(@link1.link_last_checked).to eq(@link2.link_last_checked)
      expect(@link1.link_errors).to eq(@link2.link_errors)
    end

    it "sets the link status, link warnings and last checked time to an existing homepage url status, warnings and link last checked time" do
      @local_authority = create(:local_authority, status: "broken", link_warnings: @warnings, link_last_checked: "2016-07-14 11:34:09 +0100")
      @link = create(:link, url: "http://example.com/thing", status: "ok", link_last_checked: Time.now)
      @link.url = "http://www.angus.gov.uk"
      @link.save!

      expect(@link.status).to eq(@local_authority.status)
      expect(@link.link_last_checked).to eq(@local_authority.link_last_checked)
      expect(@link.link_warnings).to eq(@local_authority.link_warnings)
    end
  end

  describe "before_create" do
    before do
      @problem_summary = "Invalid URL"
      @errors = ["No host is given in the URL."]
    end

    it "sets the link's status, link errors and last checked time to an existing url's status, link errors and last checked time" do
      @link1 = create(:link, url: "http://example.com/thing", status: "ok", problem_summary: @problem_summary, link_errors: @errors, link_last_checked: "2016-07-14 11:34:09 +0100")
      @link2 = create(:link, url: "http://example.com/thing")
      expect(@link2.status).to eq(@link1.status)
      expect(@link2.link_errors).to eq(@link1.link_errors)
      expect(@link2.link_last_checked).to eq(@link1.link_last_checked)
    end
  end

  it "sets the link's status, link errors, link warnings and last checked time to nil if there is not already an existing URL" do
    @link = create(:link, url: "http://example.com/thing")
    expect(@link.status).to be nil
    expect(@link.link_last_checked).to be nil
    expect(@link.link_errors).to be_empty
    expect(@link.link_warnings).to be_empty
  end
end

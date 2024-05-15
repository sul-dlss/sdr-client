# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::UpdateResource do
  before do
    SdrClient::RedesignedClient.configure(
      email: 'testing@example.edu',
      password: 'password',
      url: 'http://example.com/'
    )
  end

  describe 'run' do
    subject(:updater) { described_class.run(model: model, **optional_params) }

    let(:model) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:gf123df7654',
        access: { view: 'world', download: 'world' },
        type: Cocina::Models::ObjectType.book,
        version: 2,
        description: {
          title: [{ value: 'This is my object' }],
          purl: 'https://purl.stanford.edu/gf123df7654'
        },
        administrative: { hasAdminPolicy: 'druid:bc123df4567' },
        identification: { sourceId: 'googlebooks:12345' },
        label: 'This is my object',
        structural: {}
      )
    end
    let(:response_body) { '{"jobId":9}' }
    let(:response_status) { 202 }
    let(:optional_params) { {} }
    let(:update_url) { 'http://example.com/v1/resources/druid:gf123df7654' }

    before do
      stub_request(:put, update_url)
        .with(body: model.to_json)
        .to_return(status: response_status, body: response_body)
      allow(SdrClient::RedesignedClient.config.logger).to receive_messages(%i[info debug])
    end

    it { is_expected.to eq 9 }

    it 'logs a debug message showing the request body' do
      updater
      expect(SdrClient::RedesignedClient.config.logger).to have_received(:debug).once.with(/Starting update with model/)
    end

    it 'logs an info message showing the response' do
      updater
      expect(SdrClient::RedesignedClient.config.logger).to have_received(:info).once.with(/Response from server/)
    end

    context 'with a version description' do
      let(:optional_params) { { version_description: 'Updated metadata' } }
      let(:update_url) { 'http://example.com/v1/resources/druid:gf123df7654?versionDescription=Updated%20metadata' }

      it { is_expected.to eq 9 }
    end

    context 'with a user_versions' do
      let(:optional_params) { { user_versions: 'none' } }
      let(:update_url) { 'http://example.com/v1/resources/druid:gf123df7654?user_versions=none' }

      it { is_expected.to eq 9 }
    end
  end
end

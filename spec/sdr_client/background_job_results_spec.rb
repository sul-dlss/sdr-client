# frozen_string_literal: true

RSpec.describe SdrClient::BackgroundJobResults do
  describe '.show' do
    subject { described_class.show(url: 'https://sdr-api-server:3000', job_id: '3') }

    before do
      stub_request(:get, 'https://sdr-api-server:3000/v1/background_job_results/3')
        .to_return(status: status_code, body: "{\"status\":\"#{status}\"}", headers: {})
      allow(SdrClient::Credentials).to receive(:read).and_return('{"token":"zaa","exp":"2020-04-19"}')
    end

    context 'when ok' do
      let(:status_code) { 200 }
      let(:status) { 'completed' }

      it 'returns the job results' do
        expect(subject['status']).to eq(status)
      end
    end

    context 'when accepted' do
      let(:status_code) { 202 }
      let(:status) { 'pending' }

      it 'returns the job results' do
        expect(subject['status']).to eq(status)
      end
    end

    context 'when error' do
      let(:status_code) { 500 }
      let(:status) { 'error' }

      it 'raises' do
        expect { subject }.to raise_error(/unexpected response: 500/)
      end
    end
  end
end

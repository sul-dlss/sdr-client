# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::JobStatus do
  subject(:job) { described_class.new(job_id: '3') }

  let(:output) { { druid: '', errors: nil } }
  let(:response_body) do
    {
      status: status,
      output: output
    }
  end
  let(:status) { 'complete' }
  let(:url) { 'https://sdr-api.example.edu' }

  before do
    SdrClient::RedesignedClient.configure(
      email: 'testing@example.edu',
      password: 'password',
      url: url
    )
    stub_request(:get, "#{url}/v1/background_job_results/3")
      .to_return(status: status_code, body: response_body.to_json, headers: {})
    job.complete? # simulate the API call
  end

  context 'when complete' do
    let(:status_code) { 200 }

    context 'without errors' do
      let(:output) { { druid: 'druid:bb123cc4567', errors: nil } }

      describe '#complete?' do
        it 'returns true' do
          expect(job).to be_complete
        end
      end

      describe '#druid' do
        it 'returns the output druid' do
          expect(job.druid).to eq('druid:bb123cc4567')
        end
      end

      describe '#errors' do
        it 'returns nil' do
          expect(job.errors).to be_nil
        end
      end
    end

    context 'with errors' do
      let(:output) { { druid: '', errors: [{ detail: 'failed!' }] } }

      describe '#complete?' do
        it 'returns true' do
          expect(job).to be_complete
        end
      end

      describe '#druid' do
        it 'returns an empty string' do
          expect(job.druid).to eq('')
        end
      end

      describe '#errors' do
        it 'returns the list of errors' do
          expect(job.errors).to eq([{ 'detail' => 'failed!' }])
        end
      end
    end
  end

  context 'when pending' do
    let(:status_code) { 202 }
    let(:status) { 'pending' }

    describe '#complete?' do
      it 'returns false' do
        expect(job).not_to be_complete
      end
    end

    it 'returns an empty string' do
      expect(job.druid).to eq('')
    end

    describe '#errors' do
      it 'returns nil' do
        expect(job.errors).to be_nil
      end
    end
  end

  context 'when processing' do
    let(:status_code) { 202 }
    let(:status) { 'processing' }

    describe '#complete?' do
      it 'returns false' do
        expect(job).not_to be_complete
      end
    end

    it 'returns an empty string' do
      expect(job.druid).to eq('')
    end

    describe '#errors' do
      it 'returns nil' do
        expect(job.errors).to be_nil
      end
    end
  end

  describe '#wait_until_complete' do
    let(:results) do
      [
        { status: 'pending', output: {} },
        { status: 'processing', output: {} },
        { status: 'complete', output: { errors: [{ 'druid:foo' => ['druid:bar'] }] } }
      ]
    end
    let(:status_code) { 200 } # this is for the first call only

    before do
      stub_request(:get, "#{url}/v1/background_job_results/3")
        .to_return(status: 202, body: results[0].to_json, headers: {})
      stub_request(:get, "#{url}/v1/background_job_results/3")
        .to_return(status: 202, body: results[1].to_json, headers: {})
      stub_request(:get, "#{url}/v1/background_job_results/3")
        .to_return(status: 200, body: results[2].to_json, headers: {})
    end

    context 'when it completes before the timeout' do
      it 'loops until the job status is complete and returns an output hash' do
        output = job.wait_until_complete
        expect(output).to be false
        expect(job.errors).to eq([{ 'druid:foo' => ['druid:bar'] }])
      end
    end

    context 'when it times out' do
      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      it 'sets an error' do
        output = job.wait_until_complete
        expect(output).to be false
        expect(job.errors).to eq(['Not complete after 180 seconds'])
      end
    end
  end
end

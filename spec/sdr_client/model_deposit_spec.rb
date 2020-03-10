# frozen_string_literal: true

RSpec.describe SdrClient::Deposit do
  describe '.run_model' do
    subject(:run) do
      described_class.model_run(files: files, request_dro: request_dro, url: upload_url)
    end

    let(:process) { instance_double(SdrClient::Deposit::ModelProcess, run: true) }

    let(:files) { ['spec/fixtures/file1.txt'] }

    let(:request_dro) { instance_double(Cocina::Models::RequestDRO) }

    let(:upload_url) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }

    before do
      allow(SdrClient::Credentials).to receive(:read).and_return('token')
      allow(SdrClient::Deposit::ModelProcess).to receive(:new).and_return(process)
    end

    it 'runs the process' do
      run
      expect(SdrClient::Deposit::ModelProcess).to have_received(:new)
        .with(files: files,
              request_dro: request_dro,
              token: 'token',
              url: upload_url,
              logger: Logger)

      expect(process).to have_received(:run)
    end
  end
end

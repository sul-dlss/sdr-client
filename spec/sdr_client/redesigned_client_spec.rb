# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient do
  subject(:client) { described_class.configure(**configure_args) }

  let(:configure_args) do
    {
      email: email,
      password: password,
      url: url
    }
  end
  let(:email) { 'dummy@example.org' }
  let(:password) { 'supersekrit' }
  let(:url) { 'https://sdr-api.example.edu' }

  describe '.configure' do
    it 'returns a singleton instance' do
      expect(client).to eq(described_class.instance)
    end

    it 'defaults request options' do
      expect(client.config.request_options).to eq(described_class.default_request_options)
    end

    it 'defaults the logger' do
      expect(client.config.logger).to be_a(Logger)
    end

    context 'without email, password, and token_refresher args' do
      let(:configure_args) { { url: url } }

      it 'raises an argument error' do
        expect { client }.to raise_error(ArgumentError)
      end
    end

    context 'when providing a token refresher callable instead of email and password args' do
      let(:configure_args) { { url: url, token_refresher: -> { true } } }

      it 'returns a singleton instance' do
        expect(client).to eq(described_class.instance)
      end
    end
  end

  describe '#config' do
    it 'includes a dummy token' do
      expect(client.config.token).to eq('a temporary dummy token to avoid hitting the API before it is needed')
    end

    it 'includes a url' do
      expect(client.config.url).to eq(url)
    end

    it 'includes a email' do
      expect(client.config.email).to eq(email)
    end

    it 'includes a password' do
      expect(client.config.password).to eq(password)
    end
  end

  describe '.deposit_model' do
    let(:fake_instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:instance).and_return(fake_instance)
      allow(fake_instance).to receive(:deposit_model)
    end

    it 'delegates to instance#deposit_model' do
      described_class.deposit_model
      expect(fake_instance).to have_received(:deposit_model).once
    end
  end

  describe '#deposit_model' do
    let(:fake_deposit) { instance_double(described_class::Deposit, deposit_model: nil) }

    before do
      allow(described_class::Deposit).to receive(:new).and_return(fake_deposit)
    end

    it 'delegates to Deposit#deposit_model' do
      # NOTE: This would ordinarily not be called without args, but we are
      #       testing the delegation here not the impl details
      client.deposit_model
      expect(fake_deposit).to have_received(:deposit_model).once
    end
  end

  describe '.find' do
    let(:fake_instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:instance).and_return(fake_instance)
      allow(fake_instance).to receive(:find)
    end

    it 'delegates to instance#find' do
      described_class.find
      expect(fake_instance).to have_received(:find).once
    end
  end

  describe '#find' do
    let(:fake_find) { instance_double(described_class::Find, run: nil) }

    before do
      allow(described_class::Find).to receive(:new).and_return(fake_find)
    end

    it 'delegates to Find#run' do
      client.find
      expect(fake_find).to have_received(:run).once
    end
  end

  describe '.update_model' do
    let(:fake_instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:instance).and_return(fake_instance)
      allow(fake_instance).to receive(:update_model)
    end

    it 'delegates to instance#update_model' do
      described_class.update_model
      expect(fake_instance).to have_received(:update_model).once
    end
  end

  describe '#update_model' do
    let(:fake_update_model) { instance_double(described_class::UpdateResource, run: nil) }

    before do
      allow(described_class::UpdateResource).to receive(:new).and_return(fake_update_model)
    end

    it 'delegates to UpdateResource#run' do
      client.update_model
      expect(fake_update_model).to have_received(:run).once
    end
  end

  describe '.build_and_deposit' do
    let(:fake_instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:instance).and_return(fake_instance)
      allow(fake_instance).to receive(:build_and_deposit)
    end

    it 'delegates to instance#build_and_deposit' do
      described_class.build_and_deposit
      expect(fake_instance).to have_received(:build_and_deposit).once
    end
  end

  describe '#build_and_deposit' do
    let(:fake_metadata) { instance_double(described_class::Metadata, deposit: nil) }

    before do
      allow(described_class::Metadata).to receive(:new).and_return(fake_metadata)
    end

    it 'delegates to Metadata#deposit' do
      client.build_and_deposit
      expect(fake_metadata).to have_received(:deposit).once
    end
  end

  describe '.job_status' do
    let(:fake_instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:instance).and_return(fake_instance)
      allow(fake_instance).to receive(:job_status)
    end

    it 'delegates to instance#job_status' do
      described_class.job_status
      expect(fake_instance).to have_received(:job_status).once
    end
  end

  # NOTE: These tests make sure automagic token refreshing works, so you won't
  #       find that logic tested in every other method in this spec.
  describe '#job_status' do
    context 'when request is successful' do
      it 'invokes JobStatus#new' do
        expect(client.job_status(job_id: '123')).to be_a(described_class::JobStatus)
      end
    end

    context 'when token is expired' do
      before do
        stub_request(:post, "#{client.config.url}/v1/auth/login")
          .to_return(
            { status: 200, body: '{"token":"new_token"}' }
          )
        stub_request(:get, "#{client.config.url}/v1/background_job_results/123")
          .with(headers: {
                  Authorization: 'Bearer a temporary dummy token to avoid hitting the API before it is needed'
                })
          .to_return(
            { status: 401, body: 'invalid authN token' }
          )
        stub_request(:get, "#{client.config.url}/v1/background_job_results/123")
          .with(headers: { Authorization: 'Bearer new_token' })
          .to_return(
            { status: 200, body: '{"status":"complete","output":{"druid":"druid:bb111cc2222"}}' }
          )
      end

      it 'fetches a new token and retries JobStatus#complete?' do
        expect { client.job_status(job_id: '123').complete? }
          .to change(client.config, :token)
          .from('a temporary dummy token to avoid hitting the API before it is needed')
          .to('new_token')
      end
    end

    context 'when UnauthorizedError raised again upon retry' do
      let(:fake_job_status) { instance_double(described_class::JobStatus, complete?: nil) }

      before do
        allow(described_class::JobStatus).to receive(:new).and_return(fake_job_status)
        allow(described_class::Authenticator).to receive(:token).and_return('a_token', 'new_token')
        allow(fake_job_status).to receive(:complete?).and_raise(described_class::UnexpectedResponse::Unauthorized)
      end

      it 'raises an error with JobStatus#complete?' do
        expect { client.job_status(job_id: '123').complete? }
          .to raise_error(described_class::UnexpectedResponse::Unauthorized)
      end
    end
  end

  describe '#get' do
    let(:path) { 'some_path' }
    let(:response) { { 'some' => 'response' } }
    let(:status) { 200 }

    before do
      stub_request(:get, "#{url}/#{path}")
        .to_return(status: status, body: response.to_json)
    end

    it 'returns the response as a hash' do
      expect(client.get(path: path)).to eq(response)
    end

    context 'when response is successful with an empty body' do
      before do
        stub_request(:get, "#{url}/#{path}")
          .to_return(status: status, body: '')
      end

      it 'returns nil' do
        expect(client.get(path: path)).to be_nil
      end
    end

    context 'when response is unsuccessful' do
      let(:status) { 500 }

      it 'raises an error' do
        expect { client.get(path: path) }.to raise_error(RuntimeError, /unexpected response/)
      end
    end
  end

  describe '#post' do
    let(:path) { 'some_path' }
    let(:response) { { 'some' => 'response' } }
    let(:status) { 200 }

    before do
      stub_request(:post, "#{url}/#{path}")
        .to_return(status: status, body: response.to_json, headers: {})
    end

    it 'calls the API with a post' do
      expect(client.post(path: path, body: '')).to eq(response)
    end

    context 'when response is successful with an empty body' do
      before do
        stub_request(:post, "#{url}/#{path}")
          .to_return(status: status, body: '')
      end

      it 'returns nil' do
        expect(client.post(path: path, body: '')).to be_nil
      end
    end

    context 'when response is unsuccessful' do
      let(:status) { 500 }

      it 'raises an error' do
        expect { client.post(path: path, body: '') }.to raise_error(RuntimeError, /unexpected response/)
      end
    end
  end

  describe '#put' do
    let(:path) { 'some_path' }
    let(:response) { { 'some' => 'response' } }
    let(:status) { 200 }

    before do
      stub_request(:put, "#{url}/#{path}")
        .to_return(status: status, body: response.to_json, headers: {})
    end

    it 'calls the API with a put' do
      expect(client.put(path: path, body: '')).to eq(response)
    end

    context 'when response is successful with an empty body' do
      before do
        stub_request(:put, "#{url}/#{path}")
          .to_return(status: status, body: '')
      end

      it 'returns nil' do
        expect(client.put(path: path, body: '')).to be_nil
      end
    end

    context 'when response is unsuccessful' do
      let(:status) { 500 }

      it 'raises an error' do
        expect { client.put(path: path, body: '') }.to raise_error(RuntimeError, /unexpected response/)
      end
    end

    context 'when response status matches user-provided status' do
      let(:status) { 201 }

      it 'does not raise' do
        expect { client.put(path: path, body: '', expected_status: 201) }.not_to raise_error
      end
    end

    context 'when response status does not match user-provided status' do
      let(:status) { 200 }

      it 'raises an error' do
        expect { client.put(path: path, body: '', expected_status: 201) }.to raise_error(RuntimeError, /unexpected/)
      end
    end
  end
end

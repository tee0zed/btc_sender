RSpec.describe BtcSender::Key do
  let(:wif_path) { 'wif.txt' }
  let(:wif_value) { 'wif_value' }
  let(:key_provider) { double(from_wif: instance_double('Bitcoin::Key'), generate: instance_double('Bitcoin::Key', to_wif: wif_value)) }

  subject(:address) { described_class.new(key_provider) }

  before do
    allow(File).to receive(:write).and_return(32)
  end

  describe '.restore' do
    context 'when WIF file exists' do
      before { allow(File).to receive(:read).with(wif_path).and_return(wif_value) }

      it 'restores itself from file' do
        address.restore(wif_path)
        expect(address.instance).not_to be_nil
      end
    end

    context 'when WIF file does not exist' do
      before do
        allow(File).to receive(:read).with(wif_path).and_raise(Errno::ENOENT)
        allow(address).to receive(:generate_and_save)
      end

      it 'generates and saves a new address' do
        address.restore(wif_path)
        expect(address).to have_received(:generate_and_save)
      end
    end
  end

  describe '.from_string' do
    it 'sets itself from the given WIF string' do
      address.from_string(wif_value)
      expect(address.instance).not_to be_nil
    end
  end

  describe '.from_file' do
    before { allow(File).to receive(:read).with(wif_path).and_return(wif_value) }

    it 'sets itself from the WIF file' do
      address.from_file(wif_path)
      expect(address.instance).not_to be_nil
    end
  end

  describe '.generate_and_save' do
    it 'generates a new address and saves it to the default WIF file' do
      address.generate_and_save

      expect(File).to have_received(:write).with(/.*wif.*/, wif_value)
      expect(address.instance).not_to be_nil
    end
  end
end

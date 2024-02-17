describe Entities::Transaction do
  let(:utxos) do
    [{"txid"=>"0291eb2457db979bb2de2bf89b35fee067e85133aed1dca3bb0861986e98edda",
      "vout"=>0,
      "status"=>
        {"confirmed"=>true,
         "block_height"=>2577928,
         "block_hash"=>"000000000000000e22e69ce082ba48b6b656f63aefd853c97773fc9c6550886e",
         "block_time"=>1707756348},
      "value"=>balance1},
     {"txid"=>"d578bf3d61599bd394aa86cd4e04ac1d83210d000682cc91aa58016ea5b74c23",
      "vout"=>1,
      "status"=>
        {"confirmed"=>true,
         "block_height"=>2578405,
         "block_hash"=>"000000008e0e7b216830775ce111fc87db53749add9944dbc1505d70420f2d81",
         "block_time"=>1708159873},
      "value"=>balance2}]
  end

  let(:balance1) { 2_000_000 }
  let(:balance2) { 2_000_000 }
  let(:balance) { balance1 + balance2 }
  let(:amount) { 3_000_000 }
  let(:recipient) { "msT2GFQnXWTyf3r3MXBHw4sFV1jcUG4o12" }
  let(:sender) { "mugwYJ1sKyr8EDDgXtoh8sdDQuNWKYNf88" }
  let(:options) { { utxos: utxos } }
  subject(:transaction) { described_class.new(amount, recipient, sender, options) }

  describe '#build_tx' do
    context 'when the balance is greater than the sum of amount and commission' do
      before { allow(transaction).to receive(:commission).and_return(commission) }
      let(:commission) { 100 }

      it 'builds the correct transaction' do
        expect(transaction.build_tx).to be_a(Entities::Transaction)
        expect(transaction.tx).to be_a(Bitcoin::Protocol::Tx)
        expect(transaction.tx.in.size).to eq(2)
        expect(transaction.tx.out.size).to eq(2)
      end

      it 'calculates the correct commission' do
        transaction.build_tx
        expect(transaction.tx.out[1].value).to eq(balance - amount - commission)
      end
    end

    context 'when the balance is less than the sum of amount and commission' do
      let(:amount) { balance * 2 }
      it 'raises an InsufficientFundsError' do
        expect { transaction.build_tx }.to raise_error(Entities::Transaction::InsufficientFundsError)
      end
    end
  end

  describe '#to_hex' do
    it 'returns a hexadecimal string representation of the transaction' do
      transaction.build_tx
      expect(transaction.to_hex).to be_a(String)
    end
  end
end

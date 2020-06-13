RSpec.describe CardanoWallet::Byron do

  MNEMONICS12 = %w[run exist tilt jealous minute pattern bicycle hire frost slogan ship bachelor]
  MNEMONICS15 = %w[absurd seat ball together donate bulk sustain loop convince capital peanut mutual notice improve jewel]
  PASS = "Secure Passphrase"
  TXID = "1acf9c0f504746cbd102b49ffaf16dcafd14c0a2f1bbb23af265fbe0a04951cc"
  BYRON = CardanoWallet.new.byron

  def create_byron_wallet(style = "random")
    style == "random" ? mnem = MNEMONICS12 : mnem = MNEMONICS15
    BYRON.wallets.create({style: style,
                          name: "Wallet from mnemonic_sentence",
                          passphrase: PASS,
                          mnemonic_sentence: mnem
                         })['id']
  end

  def delete_all
    ws = BYRON.wallets
    ws.list.each do |w|
      ws.delete w['id']
    end
  end

  describe CardanoWallet::Byron::Wallets do

    after(:each) do
      delete_all
    end

    it "I can list byron wallets" do
      l = BYRON.wallets.list
      expect(l.code).to eq 200
    end

    it "I could get a wallet" do
      g = BYRON.wallets.get "db66f3d0d796c6aa0ad456a36d5a3ee88d62bd5d"
      expect(g.code).to eq 404
    end

    it "I could delete a wallet" do
      g = BYRON.wallets.delete "db66f3d0d796c6aa0ad456a36d5a3ee88d62bd5d"
      expect(g.code).to eq 404
    end

    it "I can create, get and delete byron icarus wallet from mnemonics" do
      wallet = BYRON.wallets.create({style: "icarus",
                         name: "Wallet from mnemonic_sentence",
                         passphrase: "Secure Passphrase",
                         mnemonic_sentence: MNEMONICS15,
                         })
      expect(wallet.code).to eq 201
      wid = wallet['id']
      expect(BYRON.wallets.get(wid).code).to eq 200
      expect(BYRON.wallets.delete(wid).code).to eq 204
    end

    it "I can create, get and delete byron random wallet from mnemonics" do
      wallet = BYRON.wallets.create({style: "random",
                         name: "Wallet from mnemonic_sentence",
                         passphrase: "Secure Passphrase",
                         mnemonic_sentence: MNEMONICS12,
                         })
      expect(wallet.code).to eq 201
      wid = wallet['id']
      expect(BYRON.wallets.get(wid).code).to eq 200
      expect(BYRON.wallets.delete(wid).code).to eq 204
    end

    it "Create param must be hash" do
      w = BYRON.wallets
      expect{w.create("That's bad param")}.to raise_error ArgumentError, "argument should be Hash"
    end

    it "Can update_metadata" do
      w = BYRON.wallets
      id = create_byron_wallet
      expect(w.update_metadata(id,{name: "New wallet name"}).code).to eq 200
    end

    it "Can update_passphrase" do
      w = BYRON.wallets
      id = create_byron_wallet
      upd = w.update_passphrase(id,{old_passphrase: "Secure Passphrase",
                                    new_passphrase: "Securer Passphrase"})
      expect(upd.code).to eq 204
    end

    it "Can see utxo" do
      id = create_byron_wallet
      utxo = BYRON.wallets.utxo(id)
      expect(utxo.code).to eq 200
    end
  end

  describe CardanoWallet::Byron::Addresses do

    after(:each) do
      delete_all
    end

    it "Can list addresses - random" do
      id = create_byron_wallet
      addresses = BYRON.addresses.list id
      expect(addresses.code).to eq 200
      expect(addresses.size).to eq 0

      BYRON.addresses.create(id, {passphrase: PASS})
      addresses = BYRON.addresses.list id
      expect(addresses.code).to eq 200
      expect(addresses.size).to eq 1
    end

    it "Can list addresses - icarus" do
      id = create_byron_wallet "icarus"
      addresses_unused = BYRON.addresses.list id, {state: "unused"}
      expect(addresses_unused.code).to eq 200
      expect(addresses_unused.size).to eq 20
    end

    it "Can list addresses - ledger" do
      id = create_byron_wallet "ledger"
      addresses_unused = BYRON.addresses.list id, {state: "unused"}
      expect(addresses_unused.code).to eq 200
      expect(addresses_unused.size).to eq 20
    end

    it "Can list addresses - trezor" do
      id = create_byron_wallet "trezor"
      addresses_unused = BYRON.addresses.list id, {state: "unused"}
      expect(addresses_unused.code).to eq 200
      expect(addresses_unused.size).to eq 20
    end

    it "Can create address - random" do
      id = create_byron_wallet
      addr = BYRON.addresses.create(id, {passphrase: PASS,
                                         address_index: 2147483648})
      expect(addr.code).to eq 201

      addr = BYRON.addresses.create(id, {passphrase: PASS})
      expect(addr.code).to eq 201
    end

    it "I could import address - random" do
      id = create_byron_wallet
      addr = BYRON.addresses.create(id, {passphrase: PASS})['id']
      addr_import = BYRON.addresses.import(id, addr)
      expect(addr_import.code).to eq 204
    end

    it "I cannot import address - icarus" do
      id = create_byron_wallet "icarus"
      addr = BYRON.addresses.list(id)[0]['id']
      addr_import = BYRON.addresses.import(id, addr)
      expect(addr_import.code).to eq 403
      expect(addr_import).to include "invalid_wallet_type"
    end

    it "I cannot import address - ledger" do
      id = create_byron_wallet "ledger"
      addr = BYRON.addresses.list(id)[0]['id']
      addr_import = BYRON.addresses.import(id, addr)
      expect(addr_import.code).to eq 403
      expect(addr_import).to include "invalid_wallet_type"
    end

    it "I cannot import address - trezor" do
      id = create_byron_wallet "trezor"
      addr = BYRON.addresses.list(id)[0]['id']
      addr_import = BYRON.addresses.import(id, addr)
      expect(addr_import.code).to eq 403
      expect(addr_import).to include "invalid_wallet_type"
    end
  end

  describe CardanoWallet::Byron::Transactions do
    after(:each) do
      delete_all
    end

    it "Can list transactions - random" do
      id = create_byron_wallet
      txs = BYRON.transactions

      expect(txs.list(id).code).to eq 200
      expect(txs.list(id,
                      {start: "2012-09-25T10:15:00Z",
                       end: "2016-11-21T10:15:00Z",
                       order: "ascending"}).code).
                      to eq 200
      expect(txs.list(id, {order: "bad_order"}).code).to eq 400
    end

    it "Can list transactions - icarus" do
      id = create_byron_wallet "icarus"
      txs = BYRON.transactions

      expect(txs.list(id).code).to eq 200
      expect(txs.list(id,
                      {start: "2012-09-25T10:15:00Z",
                       end: "2016-11-21T10:15:00Z",
                       order: "ascending"}).code).
                      to eq 200
      expect(txs.list(id, {order: "bad_order"}).code).to eq 400
    end

    it "I could send tx if I had money" do
      id = create_byron_wallet
      target_id = create_byron_wallet "icarus"
      target_addr = BYRON.addresses.list(target_id)[0]['id']

      tx_sent = BYRON.transactions.create(id, PASS, {target_addr => 1000000})
      expect(tx_sent.code).to eq 403
      expect(tx_sent).to include "not_enough_money"
    end

    it "I could estimate fees if I had money" do
      id = create_byron_wallet
      target_id = create_byron_wallet "icarus"
      target_addr = BYRON.addresses.list(target_id)[0]['id']

      fees = BYRON.transactions.payment_fees(id, {target_addr => 1000000})
      expect(fees.code).to eq 403
      expect(fees).to include "not_enough_money"
    end

    it "I could forget transaction" do
      id = create_byron_wallet
      txs = BYRON.transactions
      res = txs.forget(id, TXID)
      expect(res.code).to eq 404
    end
  end

  describe CardanoWallet::Byron::Migrations do
    after(:each) do
      delete_all
    end

    it "I could calculate migration cost" do
      id = create_byron_wallet "icarus"
      cost = BYRON.migrations.cost(id)
      expect(cost.code).to eq 403
    end

    it "I could migrate all my funds" do
      id = create_byron_wallet "random"
      target_wal_id = create_byron_wallet "icarus"
      addresses = BYRON.addresses.list(target_wal_id).map{ |a| a['id'] }
      migr = BYRON.migrations.migrate(id, PASS, addresses)
      expect(migr.code).to eq 403
    end
  end
end

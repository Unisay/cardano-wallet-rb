module CardanoWallet
  module Byron

    def self.new(opt)
      Init.new opt
    end

    class Init < Base
      def initialize opt
        super
      end

      # Get API for Byron wallets
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Byron-Wallets
      def wallets
        Wallets.new @opt
      end

      # Get API for Byron addresses
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Byron-Addresses
      def addresses
        Addresses.new @opt
      end

      # Get API for Byron transactions
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/postByronTransactionFee
      def transactions
        Transactions.new @opt
      end

      # Get API for Byron migrations
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Byron-Migrations
      def migrations
        Migrations.new @opt
      end
    end

    # Byron wallets
    # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Byron-Wallets
    class Wallets < Base
      def initialize opt
        super
      end

      # List Byron wallets
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/listByronWallets
      def list
        self.class.get("/byron-wallets")
      end

      # Get Byron wallet details
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/getByronWallet
      def get(wid)
        self.class.get("/byron-wallets/#{wid}")
      end

      # Create a Byron wallet based on the params.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/postByronWallet
      #
      # @example
      #   create({style: "random",
      #           name: "Random Wallet from mnemonic_sentence",
      #           passphrase: "Secure Passphrase",
      #           mnemonic_sentence: %w[arctic decade pink easy jar index base bright vast ocean hard pizza],
      #          })
      def create(params)
        Utils.verify_param_is_hash!(params)
        self.class.post( "/byron-wallets",
                         :body => params.to_json,
                         :headers => { 'Content-Type' => 'application/json' }
                        )
      end

      # Delete Byron wallet
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/deleteByronWallet
      def delete(wid)
        self.class.delete("/byron-wallets/#{wid}")
      end

      # Update Byron wallet's metadata
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/putByronWallet
      #
      # @example
      #   update_metadata(wid, {name: "New wallet name"})
      def update_metadata(wid, params)
        Utils.verify_param_is_hash!(params)
        self.class.put("/byron-wallets/#{wid}",
                       :body => params.to_json,
                       :headers => { 'Content-Type' => 'application/json' }
                      )
      end

      # See Byron wallet's utxo distribution
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/getByronUTxOsStatistics
      def utxo(wid)
        self.class.get("/byron-wallets/#{wid}/statistics/utxos")
      end

      # Update Byron wallet's passphrase.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/putByronWalletPassphrase
      #
      # @example
      #   update_passphrase(wid, {old_passphrase: "Secure Passphrase", new_passphrase: "Securer Passphrase"})
      def update_passphrase(wid, params)
        Utils.verify_param_is_hash!(params)
        self.class.put("/byron-wallets/#{wid}/passphrase",
                       :body => params.to_json,
                       :headers => { 'Content-Type' => 'application/json' }
                      )
      end
    end

    # Byron addresses
    # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Byron-Addresses
    class Addresses < Base
      def initialize opt
        super
      end

      # List Byron addresses.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/listByronAddresses
      #
      # @example
      #   list(wid, {state: "used"})
      def list(wid, q = {})
        q.empty? ? query = '' : query = Utils.to_query(q)
        self.class.get("/byron-wallets/#{wid}/addresses#{query}")
      end

      # Create address for Byron random wallet.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/createAddress
      # @param wid [String] wallet id
      # @param params [Hash] passphrase and (optional) address_index
      #
      # @example Create address with index.
      #   create(wid, {passphrase: "Secure Passphrase", address_index: 2147483648})
      # @example Create address with random index.
      #   create(wid, {passphrase: "Secure Passphrase"})
      def create(wid, params)
        Utils.verify_param_is_hash!(params)
        self.class.post( "/byron-wallets/#{wid}/addresses",
                         :body => params.to_json,
                         :headers => { 'Content-Type' => 'application/json' }
                        )
      end

      # Import address to Byron wallet.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/importAddress
      # @param wid [String] wallet id
      # @param addr_id [String] address id
      def import(wid, addr_id)
        self.class.put("/byron-wallets/#{wid}/addresses/#{addr_id}")
      end

    end

    # Byron transactions
    # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/postByronTransactionFee
    class Transactions < Base
      def initialize opt
        super
      end

      # List all Byron wallet's transactions.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/listByronTransactions
      #
      # @example
      #   list(wid, {start: "2012-09-25T10:15:00Z", order: "descending"})
      def list(wid, q = {})
        q.empty? ? query = '' : query = Utils.to_query(q)
        self.class.get("/byron-wallets/#{wid}/transactions#{query}")
      end

      # Create a transaction from the Byron wallet.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/postByronTransaction
      # @param wid [String] source wallet id
      # @param passphrase [String] source wallet's passphrase
      # @param payments [Hash] addres, amount pair
      #
      # @example
      #   create(wid, passphrase, {addr1: 1000000})
      def create(wid, passphrase, payments)
        payments_formatted = Utils.format_payments(payments)
        self.class.post("/byron-wallets/#{wid}/transactions",
        :body => { :payments => payments_formatted,
                   :passphrase => passphrase
                 }.to_json,
        :headers => { 'Content-Type' => 'application/json' } )
      end

      # Estimate fees for transaction
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/postTransactionFee
      #
      # @example
      #   payment_fees(wid, {addr1: 1000000})
      def payment_fees(wid, payments)
        payments_formatted = Utils.format_payments(payments)
        self.class.post("/byron-wallets/#{wid}/payment-fees",
        :body => { :payments => payments_formatted }.to_json,
        :headers => { 'Content-Type' => 'application/json' } )
      end

      # Forget a transaction.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/deleteByronTransaction
      def forget(wid, txid)
        self.class.delete("/byron-wallets/#{wid}/transactions/#{txid}")
      end
    end

    # Byron migrations
    # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Byron-Migrations
    class Migrations < Base
      def initialize opt
        super
      end

      # Calculate migration cost
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/getByronWalletMigrationInfo
      def cost(wid)
        self.class.get("/byron-wallets/#{wid}/migrations")
      end

      # Migrate all funds from Byron wallet.
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/migrateByronWallet
      # @param wid [String] wallet id
      # @param passphrase [String] wallet's passphrase
      # @param [Array] array of addresses
      def migrate(wid, passphrase, addresses)
        self.class.post("/byron-wallets/#{wid}/migrations",
        :body => { :addresses => addresses,
                   :passphrase => passphrase
                 }.to_json,
        :headers => { 'Content-Type' => 'application/json' } )
      end

    end
  end
end
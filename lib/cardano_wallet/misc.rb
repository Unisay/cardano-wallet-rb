module CardanoWallet
  module Misc

    def self.new(opt)
      Init.new opt
    end

    class Init < Base
      def initialize opt
        super
      end

      # Call API for Network
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Network
      def network
        Network.new @opt
      end
    end

    # API for Network
    # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#tag/Network
    class Network < Base
      def initialize opt
        super
      end

      # Get network information
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/getNetworkInformation
      def information
        self.class.get("/network/information")
      end

      # Check network clock
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/getNetworkClock
      def clock
        self.class.get("/network/clock")
      end

      # Check network parameters
      # @see https://input-output-hk.github.io/cardano-wallet/api/edge/#operation/getNetworkParameters
      def parameters(epoch_id)
        self.class.get("/network/parameters/#{epoch_id}")
      end

    end
  end
end
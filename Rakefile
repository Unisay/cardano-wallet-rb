require "bundler/gem_tasks"
require "rspec/core/rake_task"
require_relative "lib/cardano_wallet"
require_relative "spec/test_utils"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :wait_until_node_synced do
  puts "\n  >> Wait for node to be synced"

  network = CardanoWallet.new.misc.network
  timeout = 180
  current_time = Time.now
  timeout_treshold = current_time + timeout
  puts "Timeout: #{timeout}s"
  puts "Threshold: #{timeout_treshold}"
  begin
    current_time = Time.now
    while network.information["sync_progress"]["status"] == "syncing" do
      puts "Syncing... #{network.information["sync_progress"]["progress"]["quantity"]}%"
      sleep 15
    end
  rescue
    retry if (current_time <= timeout_treshold)
    raise("Could not connect to wallet within #{timeout} seconds...")
  end

  puts "\n>> Cardano-node and cardano-wallet are synced! <<"
end

task :start_node_and_wallet do
  puts "\n  >> Set up and start cardano-node and cardano-wallet"

  if is_win?
    cd = Dir.pwd
    # create cardano-node.bat file
    node_cmd = "#{cd}/cardano-node.exe run --config #{cd}/configs/testnet-config.json --topology #{cd}/configs/testnet-topology.json --database-path #{ENV['NODE_DB']} --socket-path \\\\.\\pipe\\cardano-node-testnet"
    File.open("cardano-node.bat", "w") do |f|
      f.write(node_cmd)
    end

    # create cardano-wallet.bat file
    wallet_cmd = "#{cd}/cardano-wallet.exe serve --node-socket \\\\.\\pipe\\cardano-node-testnet --testnet #{cd}/configs/testnet-byron-genesis.json --database #{ENV['WALLET_DB']} --token-metadata-server #{ENV['TOKEN_METADATA']}"
    File.open("cardano-wallet.bat", "w") do |f|
      f.write(wallet_cmd)
    end

    install_node = "nssm install cardano-node #{cd}/cardano-node.bat"
    install_wallet = "nssm install cardano-wallet #{cd}/cardano-wallet.bat"
    start_node = "nssm start cardano-node"
    start_wallet = "nssm start cardano-wallet"

    puts install_node
    puts install_wallet
    puts start_node
    puts start_wallet

    puts `#{install_node}`
    puts `#{install_wallet}`
    puts `#{start_node}`
    puts `#{start_wallet}`
  else
    cd = Dir.pwd
    start_node = "#{cd}/cardano-node run --config #{cd}/configs/*-config.json --topology #{cd}/configs/*-topology.json --database-path #{ENV['NODE_DB']} --socket-path #{cd}/node.socket"
    start_wallet = "#{cd}/cardano-wallet serve --node-socket #{cd}/node.socket --testnet #{cd}/configs/*-byron-genesis.json --database #{ENV['WALLET_DB']} --token-metadata-server #{ENV['TOKEN_METADATA']}"

    puts start_node
    puts start_wallet

    puts `screen -dmS NODE #{start_node}`
    puts `screen -dmS WALLET #{start_wallet}`
    puts `screen -ls`
  end
end

task :get_latest_bins do
  puts "\n  >> Get latest node and wallet binaries from Hydra"

  wget(get_latest_binary_url)
  if is_win?
    puts `unzip binary-dist`
    puts `dir`

    puts "cardano-node version:"
    puts `cardano-node.exe version`

    puts "cardano-wallet version:"
    puts `cardano-wallet.exe version`
  else

    puts `tar -xvf binary-dist`
    puts `cp -r cardano-wallet-*/* ./`

    puts "cardano-node version:"
    puts `./cardano-node version`

    puts "cardano-wallet version:"
    puts `./cardano-wallet version`
  end
end

task :get_latest_configs, [:env] do |task, args|
  puts "\n  >> Get latest configs for '#{args[:env]}'"

  base_url = get_latest_configs_base_url
  env = args[:env]
  path = Dir.pwd + "/configs"
  mkdir(path)
  wget("#{base_url}/#{env}-config.json", "#{path}/#{env}-config.json")
  wget("#{base_url}/#{env}-byron-genesis.json", "#{path}/#{env}-byron-genesis.json")
  wget("#{base_url}/#{env}-shelley-genesis.json", "#{path}/#{env}-shelley-genesis.json")
  wget("#{base_url}/#{env}-topology.json", "#{path}/#{env}-topology.json")
end

##
# NODE_DB=./node_db WALLET_DB=./wallet_db TOKEN_METADATA=http://metadata-server-mock.herokuapp.com/ bundle exec rake run_on["testnet"]
task :run_on, [:env] do |task, args|
  puts "\n  >> Set up env and run all tests"

  Rake::Task[:get_latest_bins].invoke
  Rake::Task[:get_latest_configs].invoke(args[:env])
  Rake::Task[:start_node_and_wallet].invoke
  Rake::Task[:wait_until_node_synced].invoke
  Rake::Task[:spec].invoke
end

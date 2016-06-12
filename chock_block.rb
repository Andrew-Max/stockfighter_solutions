require 'rubygems'
require 'httparty'
require 'pry'
require 'json'

API_KEY = "3dbde3a2309d0a08d967b361f1a4a3ed1c6297b5"
GM_BASE_URL = "https://www.stockfighter.io"
API_BASE_URL = "https://api.stockfighter.io/ob/api"

module StarfighterAPI
  AUTH_HEADER = {"X-Starfighter-Authorization" => API_KEY}

  def self.start_level(level_name)
    HTTParty.post("#{GM_BASE_URL}/gm/levels/#{level_name}", headers: AUTH_HEADER)
  end

  def self.stop_instance(game)
    HTTParty.post("#{GM_BASE_URL}/gm/instances/#{game.instance}/stop", headers: AUTH_HEADER)
  end

  def self.post_buy(game, order)
    HTTParty.post("#{API_BASE_URL}/venues/#{game.venue}/stocks/#{game.ticker}/orders",
                           body: JSON.dump(order),
                           headers: AUTH_HEADER
                           )
  end

  def self.get_orderbook(game)
    HTTParty.get("#{API_BASE_URL}/venues/#{game.venue}/stocks/#{game.ticker}", headers: AUTH_HEADER)
  end

  def self.get_instance(game)
    HTTParty.get("#{GM_BASE_URL}/gm/instances/#{game.instance}", headers: AUTH_HEADER)
  end
end

class Game
  attr_accessor :account, :venue, :ticker, :instance

  def start
    response = StarfighterAPI::start_level("chock_a_block")
    @account = response["account"]
    @venue = response["venues"][0]
    @ticker = response["tickers"][0]
    @instance = response["instanceId"]
    puts response
  end

  def stop
    response = StarfighterAPI::stop_instance(@instance)
  end
end

class Trader 
  QUANTITY = 1500
  
  def initialize(game)
    @game = game
    @@order_factory = OrderFactory.new(@game)
    @ordersFilledCounter = 0
  end


  def trade
    initial_market_order = @@order_factory.create_order(1, 1, "buy", "market")
    post_buy(initial_market_order)
    sleep(5)
    base_target = get_target
    run_order_loop(base_target)
    @game.stop
  end

  private 

  def run_order_loop(base_target)
    while @ordersFilledCounter <= 100000
      order = @@order_factory.create_order(QUANTITY, base_target, "buy", "limit")   
      response = post_buy(order)
      binding.pry
    end
  end

  def post_buy(order)
    response = StarfighterAPI::post_buy(@game, order)
    @ordersFilledCounter += response["totalFilled"]
    response
  end

  def get_asks
    response = StarfighterAPI::get_orderbook(@game)
    response["asks"]
  end

  def get_target
    response = nil
    while response == nil
      response = StarfighterAPI::get_instance(@game)
    end
    flash_message = response["flash"]["info"]
    regex = /\d\d\.\d\d\.$/
    target = regex.match(flash_message).to_s.chop.to_f
  end
end

class OrderFactory
   def initialize(game)
    @game = game
  end

  def create_order(quantity, price, direction, type)
    {
      "account" => @game.account,
      "venue" => @game.venue,
      "symbol" => @game.ticker,
      "qty" => quantity,
      "ptice" => price,
      "direction" => direction,
      "orderType" => type
    }
  end
end

class GamePlayer
  def play
    game = Game.new
    game.start
    trader = Trader.new(game)
    trader.trade
  end
end

GamePlayer.new.play

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

  def self.stop_instance(instance_id)
    HTTParty.post("#{GM_BASE_URL}/gm/instances/#{instance_id}/stop", headers: AUTH_HEADER)
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

game = Game.new
game.start
game.stop
require 'sinatra/base'
require 'sinatra-websocket'
require 'logger'
require 'mysql2'
require_relative './services/database_service'

class MainApplication < Sinatra::Base
  def initialize
    super
    @semaphore = Mutex.new
    @dbclient = DBClientFactory()
  end
  set :logging, true
  set :server, 'thin'
  set :sockets, []
  set :public_folder, 'public'

  get '/' do
    erb :view_index
  end

  get '/play_game/:id' do |id|
    erb :view_game
  end

  get '/new_game' do
    _encode = ''
    @semaphore.synchronize {
      @max_id = 0
      @dbclient.query('SELECT MAX(game_id) as _max from games;').each do |row|
        @max_id = row['_max'] if row['_max']
      end
      @max_id += 1
      _encode = @max_id.to_s(36)
      @dbclient.query("INSERT INTO games (game_id, base64_hash) VALUES (#{@max_id}, \"#{_encode}\");")
    }
    return _encode
  end

  get '/register' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
        end
        ws.onmessage do |msg|
          EM.next_tick { settings.sockets.each { |s| s.send(msg) } }
        end
        ws.onclose do
          warn('websocket closed')
          settings.sockets.delete(ws)
        end
      end
    end
  end
end

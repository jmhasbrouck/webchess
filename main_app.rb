require 'sinatra/base'
require 'sinatra-websocket'
require 'logger'
require 'mysql2'
require 'json'
require_relative './models/player'
require_relative './services/database_service'

class MainApplication < Sinatra::Base
  def initialize
    super
    @semaphore = Mutex.new
    @dbclient = DBClientFactory()
    @logger = Logger.new(STDOUT)
    @game_players_map = {}
    @sockets_game_map = {}
    @game_id_count = {}
    @get_fen_prepared_statement = @dbclient.prepare('SELECT forsyth_edwards_notation from games where base32_hash = ?')
    @update_fen_prepared_statement = @dbclient.prepare('UPDATE games SET forsyth_edwards_notation = ? WHERE base32_hash = ?')
  end
  set :logging, true
  set :server, 'thin'
  set :sockets, []
  set :public_folder, 'public'

  get '/' do
    erb :view_index
  end

  get '/game/:id' do |id|
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
      @dbclient.query("INSERT INTO games (game_id, base32_hash, forsyth_edwards_notation) VALUES (#{@max_id}, \"#{_encode}\", \"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1\");")
    }
    return _encode
  end

  get '/connect' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
        end
        ws.onmessage do |msg|
            warn(msg)
            _json = JSON.parse(msg)
            case _json['__type']
            when 'connect'
                _hash = _json['hash']
                @sockets_game_map[ws] = _hash
                player = nil
                if (@game_players_map.has_key?(_hash))
                    playerIsWhite = !(@game_players_map[_hash].last.isWhite)
                    player = Player.new ws, playerIsWhite
                    @game_players_map[_hash] << player
                else
                    player = Player.new ws, true
                    @game_players_map[_hash] = [player]
                end
                result = @get_fen_prepared_statement.execute(_hash)
                result.each do |row|
                    ws.send({'fen': row['forsyth_edwards_notation'], 'color': player.isWhite ? "white" : "black"}.to_json)
                end
            when 'put_fen'
                @semaphore.synchronize {
                    result = @update_fen_prepared_statement.execute(_json['fen'], _json['hash'])
                    if (@game_players_map.has_key?(_json['hash']))
                        @game_players_map[_json['hash']].each do |player|
                            player.socket.send({'fen': _json['fen']}.to_json)
                        end
                    end
                }
            else

            end
        end
        ws.onclose do
          warn('websocket closed')
          if (@sockets_game_map.has_key?(ws))
            _hash = @sockets_game_map[ws]
            player_to_delete = nil
            @game_players_map[_hash].each do |player|
                if (player.socket == ws)
                    player_to_delete = player
                    break
                end
            end
            if (player_to_delete != nil) 
                @game_players_map[_hash].delete(player_to_delete)
                if (@game_players_map[_hash].empty?)
                    @game_players_map.delete(_hash)
                end
            end
            @sockets_game_map.delete(ws)
          end
          settings.sockets.delete(ws)
        end
      end
    end
  end
end

require 'mysql2'

def DBClientFactory
  @_dbclient = Mysql2::Client.new(host: 'localhost', username: 'jhasbrouck', password: 'password')
  @_dbclient.query('CREATE DATABASE IF NOT EXISTS mydb;')
  @_dbclient.query('USE mydb;')
  @_dbclient.query("CREATE TABLE IF NOT EXISTS games
                    (game_id INT AUTO_INCREMENT PRIMARY KEY,
                    base64_hash VARCHAR(6) UNIQUE,
                    moves_json MEDIUMTEXT);")
  @_dbclient
end

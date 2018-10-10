require 'mysql2'

def DBClientFactory
  @_dbclient = Mysql2::Client.new(host: ENV['RDS_HOSTNAME'], username: ENV['RDS_USERNAME'], password: ENV['RDS_PASSWORD'])
  @_dbclient.query("CREATE DATABASE IF NOT EXISTS #{ ENV['RDS_DB_NAME'] }")
  @_dbclient.query('USE mydb;')
  @_dbclient.query("CREATE TABLE IF NOT EXISTS games
                    (game_id INT AUTO_INCREMENT PRIMARY KEY,
                    base32_hash VARCHAR(6) UNIQUE,
                    forsyth_edwards_notation  MEDIUMTEXT);")
  @_dbclient
end


require 'sinatra-websocket'

class Player
    def initialize(ws, isWhite)
        @ws = ws
        @isWhite = isWhite
    end
    def isWhite
        @isWhite
    end
    def socket
        @ws
    end
    def isWhite= _isWhite
        @isWhite = _isWhite
    end
    def socket= _socket
        @ws = _socket
    end
end

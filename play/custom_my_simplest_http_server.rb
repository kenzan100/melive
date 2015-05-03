require 'json'
require 'socket'
require 'uri'

class MELive
  def self.accept_card_suggestion(msg_body)
    card_hash = parse(msg_body)
    File.open("judge/TBD/#{card_hash[:name]}_#{Time.now.to_i}.json", 'a+') do |file|
      file.puts card_hash.to_json
    end
  end

  def self.parse(msg_body)
    h = {}
    msg_body.split('&').each do |elem|
      k, v = elem.split('=')
      h[k] = v
    end
    {
      name:       h['card_name'],
      pic_url:    h['card_pic_url'],
      parameters: {
        h['card_param_name'] => {
          val:  h['card_param_val'].to_i,
          unit: h['card_param_unit'],
          reasoning:  h['card_param_reasoning']
        }
      }
    }
  end
end

class MyHTTPServer
  WEB_ROOT = './public'

  CONTENT_TYPE_MAPPING = {
    html: 'text/html',
    txt:  'text/plain',
    png:  'image/png',
    jpg:  'image/jpeg',
    json: 'application/json'
  }

  # defaults to binary data
  DEFAULT_CONTENT_TYPE = 'application/octet-stream'

  def initialize
    @server = TCPServer.new 'localhost', 2345
  end

  def start
    loop do
      socket = @server.accept

      req_line = socket.gets
      STDERR.puts req_line
      next unless req_line

      req_uri = req_line.split(" ")[1]
      req_path = URI.unescape(URI(req_uri).path)
      if req_line.split(" ").first == 'POST'
        case req_path
        when '/submit'
          msg_body = read_msg_body(socket)
          MELive.accept_card_suggestion(msg_body)

          response = "Thank you for submitting! When judges decide the card is valid, it's be added to your deck!"
          socket.print "HTTP/1.1 200 OK\r\n" +
            "Content-Type: text/plain\r\n" +
            "Content-Length: #{response.bytesize}\r\n" +
            "Connection: close\r\n"
          socket.print "\r\n"
          socket.print response
          socket.close
          next
        end
      end

      if req_path == '/accept'
        param_hash = Hash[req_uri.split('?')[1..-1].map{|str| str.split('=')}]
        card_path = "judge/TBD/#{param_hash['key']}.json"
        user_deck_path = "public/data/decks/#{param_hash['deck_id']}.json"
        if File.exists?(card_path)
          card_data_hash = {}
          current_deck_arr = []
          File.open(card_path, 'r'){ |f| card_data_hash = JSON.parse f.read }
          if File.exists?(user_deck_path)
            File.open(user_deck_path, 'r'){ |f| current_deck_arr = JSON.parse f.read }
          end
          current_deck_arr << card_data_hash
          File.open(user_deck_path, 'w'){ |f| f.puts current_deck_arr.to_json }
          response = "Thanks for your cooperation! The card you judged was added to the user's deck!"
        else
          response = "Paths were not found."
        end
        socket.print "HTTP/1.1 200 OK\r\n" +
          "Content-Type: text/plain\r\n" +
          "Content-Length: #{response.bytesize}\r\n" +
          "Connection: close\r\n"
        socket.print "\r\n"
        socket.print response
        socket.close
        next
      end

      # make an actual path from request line
      path = requested_file req_line

      # defaults to index.html if endpoint is directory
      path = File.join(path,'index.html') if File.directory?(path)

      if File.exists?(path) && !File.directory?(path)
        File.open(path, "rb")  do |file|
          socket.print "HTTP/1.1 200 OK\r\n" +
            "Content-Type: #{content_type(file)}\r\n" +
            "Content-Length: #{file.size}\r\n" +
            "Connection: close\r\n"

          socket.print "\r\n"

          # write the contents of the file to the socket
          IO.copy_stream file, socket
        end
      else
        msg = "File not found\n"

        socket.print "HTTP/1.1 404 Not Found\r\n" +
          "Content-Type: text/plain\r\n" +
          "Content-Length: #{msg.size}\r\n" +
          "Connection: close\r\n"

        socket.print "\r\n"

        socket.print msg
      end

      socket.close
    end
  end

  def content_type(path)
    extension = File.extname(path).split(".").last
    CONTENT_TYPE_MAPPING.fetch extension.to_sym, DEFAULT_CONTENT_TYPE
  end

  def requested_file(request_line)
    request_uri = request_line.split(" ")[1]
    path = URI.unescape(URI(request_uri).path)

    clean = []
    parts = path.split("/")
    parts.each do |part|
      next if part.empty? || part == '.'
      part == '..' ? clean.pop : clean << part
    end

    File.join(WEB_ROOT, *clean)
  end

  def read_msg_body(socket)
    body_length = 0
    socket.each_line("\r\n") do |header|
      if header.match(/Content-Length/)
        body_length = header.match(/[0-9]+/)[0].to_i
      end
      break if header == "\r\n"
    end
    socket.read body_length
  end
end

server = MyHTTPServer.new
server.start

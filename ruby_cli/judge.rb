require 'json'

return unless ARGV[0]

File.open('../data/environment.json','r') do |f|
  @game_env_hash = JSON.parse f.read
end

approved_card_json_path = ARGV[0]
File.open(approved_card_json_path, 'r') do |f|
  @approved_card_json = JSON.parse f.read
end

@game_env_hash['cards'] << @approved_card_json

File.open("../data/environment#{Time.now.to_i}.json",'w+') do |f|
  f.puts @game_env_hash.to_json
end

# post to TBD datastore
# card_candidate
require 'json'

puts "Make\n\n"

puts "name of the card?\n\n"

name = gets.chomp

puts "do you have a pic for that?(optinal. hit return for no.)\n\n"

optional_pic_url = gets.chomp

puts "now, what's the parameter name?\n\n"

param_name = gets.chomp

puts "finally, please tell us the value of this parameter for this card!\nplease supply number only. No worry, 'in what unit' is the next question.\n\n"

param_val = gets.chomp

puts "in what unit this value is?\n\n"

param_unit = gets.chomp

puts "oh, you need to tell the judges why this parameter is valid!\nsupply blank line to finish.\n\n"

reasoning = ''
while (text = gets) != "\n"
  reasoning << text
end
reasoning.chomp!

params = { name:       name,
           pic_url:    optional_pic_url,
           parameters: {
             param_name => {
               val:  param_val.to_i,
               unit: param_unit,
               reasoning:  reasoning
             }
           }
         }.to_json

File.open("../judge/TBD/#{name}.json", 'a+') do |file|
  file.puts params
end

puts "thanks for submitting! when the judges decide this card to be valid, it will appear in the game."

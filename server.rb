require 'sinatra'

get '*' do |path|
  file = File.expand_path('../build' + path + '/index.json', __FILE__)
  send_file(file)
end

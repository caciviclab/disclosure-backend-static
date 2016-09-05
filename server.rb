require 'sinatra'

get '*' do |path|
  file = File.expand_path('../build' + path + '/index.json', __FILE__)
  headers(
    'Access-Control-Allow-Origin' => '*',
  )
  send_file(file)
end

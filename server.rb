require 'sinatra'

# Make the root URL not a 404 so it's not confusing whether the site is up or
# down.
get '/' do
  url = 'https://github.com/caciviclab/disclosure-backend-static/tree/master/build'
  "<a href='#{url}'>View list of API endpoints</a>"
end

get '*' do |path|
  file = File.expand_path('../build' + path + '/index.json', __FILE__)
  headers(
    'Access-Control-Allow-Origin' => '*',
  )
  send_file(file)
end

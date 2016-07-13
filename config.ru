require 'thin'

app = proc do |env|
  body = ['I am alive!']
  [
    200,                                        # Status code
    { 'Content-Type' => 'text/html' },          # Reponse headers
    body                                        # Body of the response
  ]
end

run app

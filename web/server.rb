# require_relative '../lib/whatnext.rb'
require 'sinatra'
require 'pry-byebug'
require 'oauth'
require 'yelp'
require 'unirest'
require 'dotenv'

set :bind, "0.0.0.0"
Dotenv.load

get '/' do
  # home page
  # has landing page button to start your experience
  # after you enter you're sent to '/the_details'
  
  erb :index
end

get '/new' do
  # user inputs address -- push into destinations array
  # user inputs mode of transportation from dropdown
  # user inputs radius_filter from dropdown

  erb :new
end

post'/create' do
  # stores the user inputs from 'the_details' to use in API calls

  # redirects to '/activity'
  @@inputs = {}

  @@inputs[:address] = params["address"].gsub(/,/, '').gsub(/\s/, '+')
  @@inputs[:mode] = params["mode"].to_i
  @@inputs[:radius] = (params["radius"].to_i/0.00062137).ceil

  redirect to '/activity'

end

get '/activity' do
  # serve user page with choice of "EAT", "DRINK" or "PLAY"

  erb :activity
end

get '/type' do

  # grabs secure keys:
  consumer_key = ENV['YELP_KEY']
  consumer_secret = ENV['YELP_SECRET']
  token = ENV['YELP_TOKEN']
  token_secret = ENV['YELP_TOKEN_SECRET']  


  # tweaks path depending on selected activity:
  if params["activity"] == "EAT"
    path = "/v2/search?term=restaurants&radius_filter=#{@@inputs[:radius]}&location=#{@@inputs[:address]}" 
  elsif params["activity"] == "PLAY"
    path = "/v2/search?term=entertainment&radius_filter=#{@@inputs[:radius]}&location=#{@@inputs[:address]}"
  else
    path = "/v2/search?term=bars&radius_filter=#{@@inputs[:radius]}&location=#{@@inputs[:address]}" 
  end

  # sets up for API call:
  consumer = OAuth::Consumer.new(consumer_key, consumer_secret, {:site => "http://api.yelp.com"})
  access_token = OAuth::AccessToken.new(consumer, token, token_secret)

  # API response:
  response = JSON(access_token.get(path).body)
  # WHY DOES THIS THROW AN ERROR SOMETIMES???
  # {"error"=>
  # {"text"=>"The OAuth credentials are invalid", "id"=>"INVALID_OAUTH_CREDENTIALS"}}

  # empty hash to store restaurant info:
  @@categories = {}
  
  # send info into the hash:
  response['businesses'].each_index do |i|
    if @@categories[response['businesses'][i]['categories'][0][0]]
      @@categories[response['businesses'][i]['categories'][0][0]] << [response['businesses'][i]['name'], response['businesses'][i]['location']['display_address'].join(', ').gsub(/,/, '').gsub(/\s/, '+')]
    else
      @@categories[response['businesses'][i]['categories'][0][0]] = []
      @@categories[response['businesses'][i]['categories'][0][0]] << [response['businesses'][i]['name'], response['businesses'][i]['location']['display_address'].join(', ').gsub(/,/, '').gsub(/\s/, '+')]
    end
  end

  @@choices = Hash[@@categories.to_a.sample(2)].keys
  binding.pry
  # OVERVIEW:
  # sends selected button from actiity as term in call to Yelp API
  # API call includes address
  # API call includes preset catagory filters for activity choice

  # store results in a hash. with key of categories:
  # data['businesses'][i]['categories'][0][0]
  
  # and value is array of businesses with names/adresses(formatted for google maps): 
  # data['businesses'][i]['name']

  # redirect user to '/activity_genre/#{selected_activity}'

  # serve user 2 random keys from the hash in '/type'

  erb :types
end

get '/result' do

  @result = @@categories[params["types"]].sample[0]

  # if params["type"] == @@choices[0]
  #   @result = @@categories[@@choices[0]].sample[0]
  # else
  #   @result = @@categories[@@choices[1]].sample[0]
  # end

  # serve user a random value of the selected key from the previous hash.
  # if user says "eff that noise":
    # add name to discard_pile array
    # redirect '/select_activity'

  # add address of business to destinations array
  # provide user with link to route or link to add another destination.

  # if user requests route:
    # make call to Google Maps API
    # use address array and selected mode
    # redirect to '/map'

  # if user requests to add activity:
    # redirect to '/select_activity'
  erb :result
end

get '/map' do
  # provide user a mapped route
  erb :map
end



## only need a post when there is a form!!


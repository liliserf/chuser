# require_relative '../lib/whatnext.rb'
require 'sinatra'
require 'pry-byebug'
# require 'unirest'
# require 'dotenv'

  set :bind, "0.0.0.0"
  # Dotenv.load

get '/' do
  # home page
  # has landing page button to start your adventure
  # after you enter you're sent to '/the_details'
  "Doin Thangs"
end

get 'the_details' do
  # user inputs address -- push into destinations array
  # user inputs mode of transportation from dropdown
  # user inputs radius_filter from dropdown
end

post'submit_details' do
  # stores the user inputs from 'the_details' to use in API calls

  # redirects to '/select_activity'
end

get '/select_activity' do
  # serve user page with choice of "EAT", "DRINK" or "PLAY"

  # sends selected button as term in call to Yelp API
  # API call includes address
  # API call includes preset catagory filters for activity choice

  # store results in a hash. with key:
  # data['businesses'][i]['categories'][0][0]
  
  # and value is array: 
  # data['businesses'][i]['name']

  # redirect user to '/activity_genre/#{selected_activity}'
end

get '/activity_genres/#{selected_activity}' do
  # serve user 2 random keys from the hash in '/select_activity'
  # user clicks button

  # redirects to '/destination'
end

get '/destination' do
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
end

get '/map' do
  # provide user a mapped route
end



## only need a post when there is a form!!


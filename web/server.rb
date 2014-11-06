require 'sinatra'
require 'pry-byebug'
require 'oauth'
require 'unirest'
require 'dotenv'
require 'json'
require 'yelpify'

set :bind, "0.0.0.0"
Dotenv.load
set :sessions, true


get '/' do
  # has landing page button to start your experience
  redirect to "/new"
end

get '/new' do
  # user inputs address
  # user inputs mode of transportation from dropdown
  # user inputs radius_filter from dropdown
  
  # adds address and names to session as json: 
  session[:addresses] = [].to_json
  session[:names] = ["Starting Point"].to_json

  erb :new
end

post'/create' do
  # stores the user inputs from 'the_details' to use in API calls

  # redirects to '/activity'

  # store the user inputs from params
  new_address = params["address"].gsub(/,/, '').gsub(/\s/, '+')
  session[:mode] = params["mode"]
  session[:radius] = params["radius"]

  # push inputs into array and convert back to json for session:
  addresses = JSON.parse session[:addresses]
  addresses << new_address
  session[:addresses] = addresses.to_json

  redirect to '/activity'

end

get '/activity' do
  # serve user page with choice of "EAT", "DRINK" or "PLAY"
  
  addresses = JSON.parse session[:addresses]
  names = JSON.parse session[:names]

  # adds another requirement for yelp API to session:
  if params['next'] == "Another!"
    addresses << params['venue_loc']
    names << params['venue_name']
  end

  session[:addresses] = addresses.to_json
  session[:names] = names.to_json


  erb :activity
end

get '/type' do
# grabs secure keys:
  oauth_creds = {
    consumer_key:    ENV['YELP_KEY'],
    consumer_secret: ENV['YELP_SECRET'],
    token:           ENV['YELP_TOKEN'],
    token_secret:    ENV['YELP_TOKEN_SECRET']
  }
  @client = Yelpify.new_client(oauth_creds)

  # get the radius & address out of session 
  @radius = session[:radius]
  @addresses = JSON.parse(session[:addresses])

  # set fixed search data
  search_data = {
    "location"      => @addresses.first,
    "radius_filter" => @radius
  }

  # alters path depending on selected activity:
  if params["activity"] == "EAT"
    search_data["category_filter"] = "food,restaurants"
  elsif params["activity"] == "PLAY"
    search_data["category_filter"] = "active,arts"
  else
    search_data["category_filter"] = "bars"
  end

  # Makes API call:
  response = @client.search(search_data)

  # empty hash to store restaurant categories and info:
  session[:categories] = [].to_json


  # stores info into the hash:
  categories = {}
  response.businesses.each_index do |i|
    business = response.businesses[i]
    category = business.categories[0][0]
    if categories[category]
      categories[category] <<
        [business.name,
        business.location.display_address.join(', ').gsub(/,/, '').gsub(/\s/, '+'), 
        business.url]
    else categories[category] = [] << 
        [business.name, 
        business.location.display_address.join(', ').gsub(/,/, '').gsub(/\s/, '+'), 
        business.url]
    end
  end

  cats = categories.to_a.sample(2)
  session[:categories] = cats.to_json

  # selects 2 random keys for user to choose from:
  @choices = Hash[cats].keys

  erb :types
end

get '/result' do

  # takes categories hash out of session again:
  categories = Hash[JSON.parse session[:categories]]
  # selects output for user based on category choice:
  result = categories[params["category"]].sample

  # saves result as variables to show in view:
  @category = params['category']
  @name = result[0]
  @location = result[1]
  @url = result[2]

  erb :result
end

get '/map' do

  # grabs addresses and names from session:
  addresses = JSON.parse session[:addresses]
  names = JSON.parse session[:names]

  # adds new name/location to arrays:
  if params['next'] == "Route me!"
    addresses << params['venue_loc']
    names << params['venue_name']
  end

  # calls google API:
  new_url = URI.encode('https://maps.googleapis.com/maps/api/directions/json?origin=' +
                        addresses.first + '&destination=' + addresses.last +
                        '&waypoints=' + addresses[1..-2].join('|')  + '&mode=' +
                        session[:mode] + '&key=' + ENV['GOOGLE_MAPS_KEY'])
  google_response = Unirest.get (new_url)
  map_data = google_response.body


  # parses response into directions:
  legs = map_data["routes"].first["legs"]
  directions = legs.map { |x| x["steps"].map { |y| y["html_instructions"] } }
  places = names.take(directions.size+1)


  # creates a map with all addresses:
  if addresses.length > 2
    @map_src = ("https://www.google.com/maps/embed/v1/directions?key=" + 
                ENV['GOOGLE_MAPS_KEY'] + "&origin=" + addresses.first + 
                "&destination=" + addresses.last + "&waypoints=" + 
                addresses[1..-2].join('|') + '&mode=' + session[:mode])
  else
    @map_src = ("https://www.google.com/maps/embed/v1/directions?key=" + 
               ENV['GOOGLE_MAPS_KEY'] + "&origin=" + addresses.first + 
                "&destination=" + addresses.last + '&mode=' + session[:mode])
  end

  # selects data needed for view:s
  @data = places.zip directions
  @data[-1][-1] = ["Final destination"]
  # @last_name = @data.pop
  erb :map
end

require 'spec_helper'


describe "Chuser App" do

  let(:session) { Hash.new }

  describe 'GET /' do
    it "responds to GET" do
      get '/'
      expect(last_response).to be_ok
    end

    it "gets a form" do
      get '/'
      expect(last_response.body).to include('form')
    end

    it "sets session[:name]" do
      get '/', {}, 'rack.session' => session
      expect(JSON.parse(session[:names])).to include("Starting Point")
    end

    it "sets session[:addresses] to []" do
      get '/', {}, 'rack.session' => session
      expect(JSON.parse(session[:addresses])).to eq([])
    end
  end

  describe 'POST /create' do
    it 'adds new address to session' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      new_address = "9704+sydney+marilyn+lane+austin+tx+78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session
      get '/activity', {}, 'rack.session' => session
      expect(JSON.parse(session[:addresses])).to include(new_address)
    end

    it 'adds radius to session' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session
      get '/activity', {}, 'rack.session' => session
      expect(session[:radius]).to include("1610")
    end

    it 'adds mode to session' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session
      get '/activity', {}, 'rack.session' => session
      expect(session[:mode]).to include("walking")
    end

    it 'redirects to after submit' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session
      last_response.should be_redirect    
    end
  end

  describe 'GET /activity' do
    it "gets a form" do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session    
      get '/activity', {}, 'rack.session' => session
      expect(last_response.body).to include('form')
    end

    it 'serves user EAT, DRINK and PLAY' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session    
      get '/activity', {}, 'rack.session' => session      
      expect(last_response.body).to include('EAT', 'DRINK', 'PLAY')
    end
  end

  describe 'GET /type' do
    it 'authorizes a new yelp client' do
      oauth_creds = {
        consumer_key:    ENV['YELP_KEY'],
        consumer_secret: ENV['YELP_SECRET'],
        token:           ENV['YELP_TOKEN'],
        token_secret:    ENV['YELP_TOKEN_SECRET']
      }
      client = Yelpify.new_client(oauth_creds)
      expect(client.access_token).to_not be_nil
    end

    it 'creates an API call' do
      oauth_creds = {
        consumer_key:    ENV['YELP_KEY'],
        consumer_secret: ENV['YELP_SECRET'],
        token:           ENV['YELP_TOKEN'],
        token_secret:    ENV['YELP_TOKEN_SECRET']
      }
      client = Yelpify.new_client(oauth_creds)

      address     = "9704+sydney+marilyn+lane+austin+tx+78748"
      radius      = "1610"
      search_data = {
        "location"      => address,
        "radius_filter" => radius,
        "limit"         => 3
      }
      search_data["category_filter"] = "food,restaurants"
      VCR.use_cassette('search') do
        response = client.search(search_data)
        expect(response).to be_a(OpenStruct)
      end
    end

    it 'sorts results by category' do
      oauth_creds = {
        consumer_key:    ENV['YELP_KEY'],
        consumer_secret: ENV['YELP_SECRET'],
        token:           ENV['YELP_TOKEN'],
        token_secret:    ENV['YELP_TOKEN_SECRET']
      }
      client = Yelpify.new_client(oauth_creds)

      address     = "9704+sydney+marilyn+lane+austin+tx+78748"
      radius      = "1610"
      search_data = {
        "location"      => address,
        "radius_filter" => radius,
        "limit"         => 3
      }
      search_data["category_filter"] = "food,restaurants"
      VCR.use_cassette('search') do
        response = client.search(search_data)
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
        expect(categories).to_not be_nil
        expect(categories.length).to eq(3)
        expect(categories.values[0][0][0]).to be_a(String)
        expect(categories.values[0][0][1]).to include('+')
        expect(categories.values[0][0][2]).to include('www')
      end
    end

    it 'returns two categories' do
      oauth_creds = {
        consumer_key:    ENV['YELP_KEY'],
        consumer_secret: ENV['YELP_SECRET'],
        token:           ENV['YELP_TOKEN'],
        token_secret:    ENV['YELP_TOKEN_SECRET']
      }
      client = Yelpify.new_client(oauth_creds)

      address     = "9704+sydney+marilyn+lane+austin+tx+78748"
      radius      = "1610"
      search_data = {
        "location"      => address,
        "radius_filter" => radius,
        "limit"         => 3
      }
      search_data["category_filter"] = "food,restaurants"
      VCR.use_cassette('search') do
        response = client.search(search_data)
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
        choices = Hash[cats].keys
        expect(choices.length).to eq(2)
      end
    end

  end

  describe 'GET /result' do
    it "" do
    end
  end

  describe 'GET /map' do
    it "" do
    end
  end
  
end

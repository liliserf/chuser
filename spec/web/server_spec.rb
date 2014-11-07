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

  describe 'GET /type' do

    before do
      oauth_creds = {
        consumer_key:    ENV['YELP_KEY'],
        consumer_secret: ENV['YELP_SECRET'],
        token:           ENV['YELP_TOKEN'],
        token_secret:    ENV['YELP_TOKEN_SECRET']
      }
      @client = Yelpify.new_client(oauth_creds)
    end

    it 'creates an API call' do
      address     = "9704+sydney+marilyn+lane+austin+tx+78748"
      radius      = "1610"
      search_data = {
        "location"      => address,
        "radius_filter" => radius,
        "limit"         => 3
      }
      search_data["category_filter"] = "food,restaurants"
      VCR.use_cassette('search') do
        response = @client.search(search_data)
        expect(response).to be_a(OpenStruct)
      end
    end

    it 'sorts results by category' do
      get '/', {}, 'rack.session' => session

      VCR.use_cassette('search_single_cats') do
        session[:radius] = "1610"
        session[:addresses] = ["9704+sydney+marilyn+lane+austin+tx+78748"].to_json
        
        get '/type', { "activity" => '' }, 'rack.session' => session
        categories = JSON.parse(session[:categories])
        
        expect(session[:categories]).to include("Little Woodrow's", "Toro Negro Lounge")
        expect(categories.length).to eq(2)
      end
    end

  end

  describe 'GET /result' do

    before do
      oauth_creds = {
        consumer_key:    ENV['YELP_KEY'],
        consumer_secret: ENV['YELP_SECRET'],
        token:           ENV['YELP_TOKEN'],
        token_secret:    ENV['YELP_TOKEN_SECRET']
      }
      @client = Yelpify.new_client(oauth_creds)
    end

    it 'gives user a result' do
      get '/', {}, 'rack.session' => session

      VCR.use_cassette('search_single_cats') do
        session[:radius] = "1610"
        session[:addresses] = ["9704+sydney+marilyn+lane+austin+tx+78748"].to_json
        get '/type', { "activity" => '' }, 'rack.session' => session        
        get '/result', { "category" => 'Pubs' }, 'rack.session' => session
        expect(last_response.body).to match(/Little Woodrow's/)
      end
    end
  end

  describe 'GET /map' do
    it "gets addresses from session" do
      session[:addresses] = ["9704+sydney+marilyn+lane+austin+tx+78748",
                             "9600+S+I+35+Frontage+Rd+Austin+TX+78748",
                             "161+West+Slaughter+Ln+Austin+TX+78748"].to_json 
      session[:names]     = ["Starting Point", 
                             "Jason's Deli", 
                             "Chick-fil-a"].to_json
      session[:mode]      = "walking"
      VCR.use_cassette('get_maps') do
        get '/map', {}, 'rack.session' => session
        expect(last_response.body).to match(/Starting Point/)
        expect(last_response.body).to match(/Jason's Deli/)
        expect(last_response.body).to match(/Chick-fil-a/)
      end
    end

    xit "adds name and address to session when 'Route me!'" do
      session[:addresses] = ["9704+sydney+marilyn+lane+austin+tx+78748",
                             "9600+S+I+35+Frontage+Rd+Austin+TX+78748",].to_json
      session[:names]     = ["Starting Point", 
                             "Jason's Deli",].to_json
      params['venue_loc']  = {}
      params['venue_name'] = {}
      params['venue_loc']  = "161+West+Slaughter+Ln+Austin+TX+78748"
      params['venue_name'] = "Chick-fil-a"
      addresses = JSON.parse session[:addresses]
      names     = JSON.parse session[:names] 
      params = { 'next' => "Route me!" }

      if params['next'] == "Route me!"
        addresses << params['venue_loc']
        names     << params['venue_name']
      end

      expect(addresses.length).to eq(3)
      expect(names.length).to eq(3)
    end
  end
  
end

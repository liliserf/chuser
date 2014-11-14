require 'spec_helper'


describe "Chuser" do

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
      expect(JSON.parse(session[:names])).to include("Home")
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

    it 'serves user options' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session    
      get '/activity', {}, 'rack.session' => session      
      expect(last_response.body).to include('EAT', 'DRINK', 'PLAY')
    end

    it 'can add name/location to session' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session    
      get '/activity', {'next' => 'Another!', 'venue_loc' => "9500+S+I+H+35+Austin+TX+78748", 'venue_name' => "Little Woodrow's"}, 'rack.session' => session      
      expect(session[:addresses]).to include("9500+S+I+H+35+Austin+TX+78748")
      expect(session[:names]).to include("Little Woodrow's")
    end

    it 'does not add name/location to session when params is PASS' do
      get '/', {}, 'rack.session' => session
      address = "9704 sydney marilyn lane, austin, tx 78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session    
      get '/activity', {'next' => 'PASS!', 'venue_loc' => "9500+S+I+H+35+Austin+TX+78748", 'venue_name' => "Little Woodrow's"}, 'rack.session' => session      
      expect(session[:addresses]).not_to include("9500+S+I+H+35+Austin+TX+78748")
      expect(session[:names]).not_to include("Little Woodrow's")
    end   

  end

  it 'authorizes a new yelp client' do
    oauth_creds = {
      consumer_key:    ENV['YELP_KEY'],
      consumer_secret: ENV['YELP_SECRET'],
      token:           ENV['YELP_TOKEN'],
      token_secret:    ENV['YELP_TOKEN_SECRET']
    }
    client = Yelpify.create_new(oauth_creds)
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
      @client = Yelpify.create_new(oauth_creds)
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
      @client = Yelpify.create_new(oauth_creds)
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

  describe 'POST /map' do
    it "gets addresses from session" do
      session[:addresses] = ["9704+sydney+marilyn+lane+austin+tx+78748",
                             "9600+S+I+35+Frontage+Rd+Austin+TX+78748",
                             "161+West+Slaughter+Ln+Austin+TX+78748"].to_json 
      session[:names]     = ["Starting Point", 
                             "Jason's Deli", 
                             "Chick-fil-a"].to_json
      session[:mode]      = "walking"
      VCR.use_cassette('get_map') do
        post '/map', {'venue_loc' => "9500+S+I+H+35+Austin+TX+78748", 'venue_name' => "Little Woodrow's"}, 'rack.session' => session
        expect(last_response.body).to match(/Starting Point/)
        expect(last_response.body).to match(/Jason's Deli/)
        expect(last_response.body).to match(/Chick-fil-a/)
        expect(last_response.body).to match(/Little Woodrow's/)
      end
    end 
  end
  
end

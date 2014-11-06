require 'spec_helper'

describe "Chuser App" do

  let(:session) { Hash.new }

  describe 'GET /' do
    it "should respond to GET" do
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
      expect(JSON.parse(session[:addresses])).to eq([])
    end
  end

  describe 'POST /create' do
    it 'should add new address to session' do
      get '/', {}, 'rack.session' => session

      address = "9704+sydney+marilyn+lane+austin+tx+78748"
      post '/create', {"address" => address, "mode" => "walking", "radius" => "1610"}, 'rack.session' => session
      get '/activity', {}, 'rack.session' => session
      expect(JSON.parse(session[:addresses])).to include(address)
    end
  end

end

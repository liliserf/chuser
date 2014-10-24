require 'server_spec_helper'
require 'pry-byebug'

describe Chuser::Server do

  def app
    Chuser::Server.new
  end

  describe "GET /" do
    it "loads the homepage" do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to include "Chuser"
    end

end

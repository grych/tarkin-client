require 'spec_helper'

# Warning: this tests are based on demo version of Tarkin. Users can change the data there, so some tests may fail
URL = 'http://tarkin.tg.pl'
describe TarkinClient do
  before do
    @client = TarkinClient.new email: 'user@example.com', password: 'password0', tarkin_url: URL
  end
  describe "with valid username and password" do
    it "password should be readable" do
      expect(@client.password('/db/prod/oracle/scott')[:password]).to eq 't1ger'
    end
    it "root directory should be listable" do
      # {:directories=>[{:name=>"db", :id=>9}, {:name=>"unix", :id=>15}, {:name=>"windows", :id=>18}], :items=>[]}
      expect(@client.ls('/')[:directories]).not_to be_empty
      expect(@client.ls('/')[:items]).not_to be_nil
    end
    it "subdirectory should be listable" do
      subdir = @client.ls('/')[:directories].first[:name]
    end
    it "but you should not list item" do
      expect {@client.ls('/db/prod/oracle/scott')}.to raise_exception TarkinClientException
    end
    it "find should work" do
      found_oracles = @client.find('oracle')
      expect(found_oracles).not_to be_nil
      expect(found_oracles.count).to be 3
      found_oracles = @client.find('/db/*/oracle')
      expect(found_oracles).not_to be_nil
      expect(found_oracles.count).to be 2      
    end
  end
  describe "with pre-generated token" do
    before do
      @token_client = TarkinClient.new tarkin_url: URL, token: @client.token
    end
    it "password should be readable" do
      expect(@client.password('/db/prod/oracle/scott')[:password]).to eq 't1ger'
      expect(@client.password('/db/prod/oracle/scott')[:username]).to eq 'scott'
    end
  end
end

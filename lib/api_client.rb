require 'json'
require 'net/http'
require 'active_support/core_ext/hash/conversions'

class Net::HTTPResponse
  def deserialize
    case content_type
    when "application/xml"
      Hash.from_xml body
    when "application/json"
      JSON.parse body
    else
      body
    end
  end

  def ok?
    code == "200"
  end
end

class ApiClient
  attr_reader :req

  def initialize(base_url, **options)
    @base_url = base_url
    @headers = options[:headers]
    @auth_user = options[:username]
    @auth_password = options[:password]
  end

  def get(path, **options)
    headers = options[:headers] || @headers 
    uri = URI("#{@base_url}/#{path}")
    req = Net::HTTP::Get.new(uri)
    headers.each { |k,v| req[k] = v } if headers
    auth_user = options[:auth_user] || @auth_user
    auth_password = options[:auth_password] || @auth_password
    req.basic_auth auth_user, auth_password if auth_user && auth_password
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    @req = req
    res
  end
end

require 'highline/import'
require 'yaml'

require 'api_client'

class TarkinClient
  SETTINGS_FILES = ["#{Dir.home}/.tarkin", ".tarkin", "/etc/tarkin"]
  API = "_api/v1"

  attr_accessor :settings
  attr_reader :api_client

  # Constructor. Needs to know the Tarkin Server parameters.
  # They can be passed with three differen ways::
  #
  # * the options hash
  #   >> tc = TarkinClient.new email: 'user@example.com', password: 'password0', tarkin_url: 'http://tarkin.tg.pl'
  #   # TarkinClient <server: http://tarkin.tg.pl, authorized: true>
  #
  # * by reading the stored parameters in settings file (like ~/.tarkin)  
  #   >> tc = TarkinClient.new
  #   # TarkinClient <server: http://localhost:3000, authorized: true>
  #
  # * by asking user via command line (when file not found)
  #   >> tc = TarkinClient.new
  #   # Your Tarkin server URL: |http://tarkin.tg.pl| http://localhost:3000
  #   # Your Tarkin account email: |user@example.com| grychu@gmail.com
  #   # Password for grychu@gmail.com: ********
  #   # TarkinClient <server: http://localhost:3000, authorized: true>
  def initialize(**options)
    @authorized = false    
    if options[:email] && options[:password] && options[:tarkin_url]
      @settings = options.select { |k,v| [:email, :tarkin_url].include? k }
      @settings[:token] = get_token(@settings[:email], options[:password])
      save_settings
    else
      get_settings
    end
    @api_client = ApiClient.new(api_url, headers: { "Authorization" => "Token token=#{@settings[:token]}" })
  end

  # Returns Hash containing :id, :username and :password
  # Gets Item.id or full path to the Item as a parameter
  #
  #   >> tc.password(107)
  #   # {
  #   #       "id" => 110,
  #   # "username" => "sysdba",
  #   # "password" => "secret_top"
  #   # }
  #
  #   >> tc.password('/db/oracle/C84PCPY/sysdba')
  #   # {
  #   #       "id" => 110,
  #   # "username" => "sysdba",
  #   # "password" => "secret_top"
  #   # }
  def password(path_or_id)
    case path_or_id
    when String
      # full path given
      u = "#{path_or_id}.json"
    when Fixnum
      # Item ID given
      u = "_password/#{path_or_id}.json"
    end
    response = @api_client.get(u)
    if response.ok?
      response.deserialize
    else
      puts "Can't get password, server returns #{response.code}: #{response.message}"
    end
  end

  # Returns true, if there is a connectivity to the server
  # and you are authorized
  def authorized?
    @authorized || check_connectivity
  end

  def inspect
    "TarkinClient <server: #{@settings[:tarkin_url]}, authorized: #{authorized?}>"
  end

  private
  def api_url
    "#{@settings[:tarkin_url]}/#{API}"
  end

  def get_settings
    settings_file = SETTINGS_FILES.find {|file| File.exists? file}
    if settings_file
      @settings = YAML::load_file settings_file
    else
      new_settings
    end
  end

  def new_settings
    @settings = Hash.new
    until @settings[:token]
      @settings[:tarkin_url] = ask("Your <%= color('Tarkin', BOLD) %> server URL: ") do |q|
        q.default = @settings[:tarkin_url] || "http://tarkin.tg.pl" 
        q.validate = /^(http|https):\/\/.*/ix
      end
      @settings[:email] = ask("Your <%= color('Tarkin', BOLD) %> account email: ") do |q| 
        q.default = @settings[:email] || "user@example.com"
        q.validate = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      end
      password = ask("Password for #{@settings[:email]}: ") { |q| q.echo = "*" }
      @settings[:token] = get_token(@settings[:email], password)
    end 
    save_settings
  end

  def save_settings
    File.open(SETTINGS_FILES.first, 'w') { |f| f.puts @settings.to_yaml }
  end

  def get_token(email, password)
    begin
      # Login to the system requires basic http authorization
      client = ApiClient.new(api_url, username: email, password: password)
      response = client.get('_authorize.json')
    rescue SocketError
      say "<%= color('Cannot connect to server.', BOLD) %> Please retry."
      return nil
    end
    unless response.ok?
      say "<%= color('#{response.message}', BOLD) %>. Please retry."
      nil
    else
      @authorized = true
      response.deserialize['token']
    end
  end

  def check_connectivity
    # @authorized = api_uri['_ping'].get.ok? unless @authorized
    # @authorized = "#{api_url}/_ping".to_uri.get("", "Authorization" => "Token token=#{@settings[:token]}").ok? unless @authorized
    @api_client.get("_ping").ok? unless @authorized
  end
end

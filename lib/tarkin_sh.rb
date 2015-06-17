require 'cmd'

class TarkinSh < Cmd
  prompt_with     :prompt_command

  handle TarkinClientException, :handle_client_exception

  doc :ls, 'List contants of current directory
      -l -- verbose (long) view'
  def do_ls(args)
    if args[:args].empty?
      commands.ls @cd, args[:options].include?('l')
    else
      args[:args].each do |dir|
        commands.ls full_dir(dir), args[:options].include?('l')
      end
    end
  end

  doc :pwd, 'Print working directory'
  def do_pwd
    write @cd
  end

  doc :cd, 'Change directory'
  def do_cd(args)
    if args[:args].empty? 
      @cd = '/'
    else
      @cd = full_dir args[:args].first
    end
  end

  doc :cat, 'Show password
      aliases: more, less'
  def do_cat(args)
    args[:args].each do |item|
      commands.cat(full_dir(item))
    end
  end

  protected
  def self.start(client, commands)
    @@client = client
    @@commands = commands
    run
  end

  def setup
    @cd = '/'
  end

  def prompt_command
    "#{client.settings[:tarkin_url]}#{@cd}> "
  end

  def command_missing(command, args)
    write "tarkin: command not found: #{command}"
  end

  def handle_client_exception(exception)
    write "tarkin: #{exception.message}"
  end

  def postloop
    write "exiting..."
  end

  def tokenize_args(args)
    a = if args then args.split else [] end
    { args: a.select {|x| !x.start_with? '-'},
      options: a.select {|x| x.start_with? '-'}.map {|x| x.sub(/^-/, '')}.join.split('').uniq}
  end

  private
  def commands
    @@commands
  end

  def client
    @@client
  end

  def full_dir(dir)
    if dir.start_with? '/'
      File.absolute_path(dir)
    else
      File.absolute_path(dir, @cd)
    end
  end

end

require 'cmd'

class TarkinSh < Cmd
  SETTINGS_FILE = "#{Dir.home}/.tarkin_sh"
  HIST_LINES = 100 # how many history lines to save

  prompt_with     :prompt_command

  handle TarkinClientException, :handle_client_exception

  doc :ls, 'List contants of directory
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
      # TODO: warn if change to non-existing directory
      dir = args[:args].first
      @cd = full_dir dir
    end
  end
  def complete_cd(args)
    commands.dirs(full_dir(@cd)).collect {|x| x[:name]}.select {|x| x.start_with? args}
  end

  shortcut 'less', :cat
  shortcut 'more', :cat
  shortcut 'get', :cat
  doc :cat, 'Shows password'
  def do_cat(args)
    args[:args].each do |item|
      commands.cat(full_dir(item))
    end
  end
  def complete_cat(args)
    commands.items(full_dir(@cd)).collect {|x| x[:username]}.select {|x| x.start_with? args}
  end
  
  shortcut 'search', :find
  doc :find, 'Find for item or directory'
  def do_find(args)
    if args[:args].empty?
      commands.ls @cd, false
    else
      commands.find(args[:args])
    end
  end

  def do_help(command = nil)
    command = command[:args].first
    if command
      command = translate_shortcut(command)
      docs.include?(command) ? print_help(command) : no_help(command)
    else
      documented_commands.each {|cmd| print_help cmd}
      print_undocumented_commands if undocumented_commands?
    end
  end

  shortcut '!', 'shell'
  doc :shell, 'Executes a shell.'
  # Executes a shell, perhaps should only be defined by subclasses.
  def do_shell(line)
    line = line[:original]
    shell = ENV['SHELL']
    write shell
    write "**#{line}**"
    line.empty? ?  system(shell) : write(%x(#{line}).strip)
  end

  protected
  def self.start(client, commands)
    @@client = client
    @@commands = commands
    run
  end

  def setup
    if File.exists? SETTINGS_FILE
      settings = YAML::load_file SETTINGS_FILE
      @cd = settings[:cd]
      settings[:history].each { |h| Readline::HISTORY.push h }
    else
      @cd = '/'
    end
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
    settings = { cd: @cd, history: Readline::HISTORY.to_a.last(HIST_LINES) }
    File.open(SETTINGS_FILE, 'w') { |f| f.puts settings.to_yaml }
  end

  def tokenize_args(args)
    a = if args then args.split else [] end
    { args: a.select {|x| !x.start_with? '-'},
      options: a.select {|x| x.start_with? '-'}.map {|x| x.sub(/^-/, '')}.join.split('').uniq,
      original: args}
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

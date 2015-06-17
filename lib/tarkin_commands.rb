class String
  # taken from rails
  def truncate(truncate_at, options = {})
    s = self.gsub(/\r\n/, ' ')
    return s unless length > truncate_at

    omission = options[:omission] || '...'
    length_with_room_for_omission = truncate_at - omission.length
    stop =        if options[:separator]
        rindex(options[:separator], length_with_room_for_omission) || length_with_room_for_omission
      else
        length_with_room_for_omission
      end

    "#{s[0, stop]}#{omission}"
  end
end

class TarkinCommands
  def initialize(client)
    @client = client
  end

  def cat(pwd)
    puts @client.password(pwd)[:password]
  end

  def ls(path, long)
    list = @client.ls(URI::encode(path))
    if long
      all = (list[:directories].collect{|dir| ["#{dir[:name]}/", 'blue', dir[:created_at], dir[:updated_at], dir[:description]]} +
            list[:items].collect{|item| [item[:username], 'white', item[:created_at], item[:updated_at], item[:description]]}).sort
      unless all.empty?
        cols = 3
        len = max_len(all)
        table border: false do
          all.each do |thing|
            row do
              column thing[2].to_time.strftime('%Y-%m-%d %T'), width: 22
              column thing[3].to_time.strftime('%Y-%m-%d %T'), width: 22
              column thing[0], width: len+2, color: thing[1]
              chars_to_end = HighLine::SystemExtensions.terminal_size.first - 22*2 - (len+6)
              column thing[4].truncate(chars_to_end), width: chars_to_end
            end
          end
        end
      end
    else
      # all contains directories and users, a list of list - item and display color: [[dir1, 'blue'], [user1, 'white']]
      # reversed because we will be poping the table
      all = (list[:directories].collect{|dir| ["#{dir[:name]}/", 'blue']} + list[:items].collect{|item| [item[:username], 'white']}).sort.reverse
      unless all.empty?
        cols = columns(all)
        rows = all.count / cols + ( all.count % cols == 0 ? 0 : 1 )
        len = max_len(all)

        table border: false do
          rows.times do
            row do
              cols.times do
                item = all.pop
                column(item && item.first , width: len, color: item && item.last)
              end
            end
          end
        end
      end
    end
  end

  def find(term)
    list = @client.find(term).sort_by {|x| x[:label]}
    list.each do |thing|
      unless thing[:redirect_to].include?('#')
        puts thing[:label].blue
      else
        puts thing[:label].white
      end
    end
  end

  # Returns items only in given directory
  def items(dir)
    @client.ls(URI::encode(dir))[:items]
  end

  # Returns only dirs
  def dirs(dir)
    @client.ls(URI::encode(dir))[:directories]
  end

  private
  def max_len(array_or_arrays)
    if array_or_arrays.empty?
      nil
    else
      array_or_arrays.max_by{|x| x.first.length}.first.length
    end
  end

  def columns(array_or_arrays)
    screen_x = HighLine::SystemExtensions.terminal_size.first
    (screen_x / (max_len(array_or_arrays) + 1.0)).floor
  end
end

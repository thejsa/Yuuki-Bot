module YuukiBot

  class << self
     attr_accessor :config
  end

  require 'yaml'
  # Load Config from YAML
  @config = YAML.load_file('config/config.yml')
  @config.each do |key, value|
    if value.nil?
      puts "config.yml: #{key} is nil!"
      puts 'Corrupt or incorrect Yaml.'
      exit
    else
      puts("config.yml: Found #{key}: #{value}") if @config['verbose']
    end
  end

  @config['debug'] = false if @config['debug'].nil?

  @new_events = {}

  @config['logevents'].each { |x|
    @new_events[x] = true
    puts "Added log event: #{x}" if @config['verbose']
  }
  @config['logevents'] = @new_events

  if @config['status'].nil?
    puts 'Enter a valid status in config.yml!'
    puts 'Valid options are \'online\', \'idle\', \'dnd\' and \'invisible\'.'
    raise 'Invalid status'
  end

  if @config['token'].nil?
    raise 'No valid token entered!'
  end
  require 'easy_translate'
  
  EasyTranslate.api_key = @config['translate_api_key']

  def self.build_init
    # Transfer it into an init hash.
    init_hash = {
      token: @config['token'],
      prefixes: @config['prefixes'],
      client_id: @config['client_id'],
      parse_self: @config['parse_self'],
      parse_bots: @config['parse_bots'],
      selfbot: @config['selfbot'],
      type: @config['type'],
      game: @config['game'],
      owners: @config['owners'],

      typing_default: @config['typing_default'],
      ready: proc {|event|
        case @config['status']
          when 'idle' || 'away' || 'afk' then event.bot.idle
          when 'dnd' then event.bot.dnd
          when 'online' then event.bot.online
          when 'invisible' || 'offline' then event.bot.invisible
          when 'stream' || 'streaming' then event.bot.stream(@config['game'], @config['twitch_url'])
          else
            raise 'No valid status found.'
        end
        ignored = DB.execute("select id from userlist where ignored=1").map {|v| v[0]}
        p ignored
        ignored.each {|id|
          begin
            $cbot.bot.ignore_user($cbot.bot.user(id))
          rescue Exception => e
            p e
          end
        }

        event.bot.game = YuukiBot.config['game'] rescue nil
        puts "[READY] Logged in as #{event.bot.profile.distinct} !"
        puts "[READY] Connected to #{event.bot.servers.count} servers!"
        if event.bot.servers.count == 0
          puts '[READY] You are not connected to any servers. Use the following URL to add your first one!'
          puts "[READY] Invite URL: #{event.bot.invite_url}"
        end
      }
    }
    return init_hash
  end
end

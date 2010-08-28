#! /bin/ruby
#################################
# 
# Reg2Rep is a tool allowing you to register/un-register 
# and check registration status of any object in central
# repository.
# 
# This script depends on following gems:
# - right_aws
# - right_http_connection
#
# (c) 2010 Vanilladesk Ltd.
#
#################################

begin
  require 'right_aws'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the right_aws.  Run \'gem install right_aws\' and try again.")
  exit 1 
end

begin
  require 'optiflag'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the optiflag.  Run \'gem install optiflag\' and try again.")
  exit 1
end

begin
  require 'parseconfig'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the parseconfig.  Run \'gem install parseconfig\' and try again.")
  exit 1
end

class R2Config
  
  # repository address (e.g. EC2 endpoint)
  def address
    @address
  end

  # repository access id (e.g. EC2 access key or other repo login name)
  def access_id
    @access_id
  end

  # repository access secret (e.g. EC2 secret key or other repo password)
  def access_secret
    @access_secret
  end

  # load configuration from file
  def load(f)
    begin
      _cfg = ParseConfig.new(f)
    rescue Errno::ENOENT 
      puts "Error: The config file #{f} was not found"
      exit 2
    rescue Errno::EACCES 
      puts "Error: The config file #{f} is not readable"
      exit 2
    end

    _p = _cfg.get_params
    
    @address = _cfg.get_value('repository_address')
    @access_id = _cfg.get_value('repository_access_id')
    @access_secret = _cfg.get_value('repository_access_secret')
    puts "load: #{@address}, #{@access_id}, #{@access_secret}"
  end

  def initialize(f,a,i,s)
    load(f)
    # if specified, override specified settings
    @address = a if a != :nil
    @access_id = i if i != :nil
    @access_secret = s if s != :nil
    puts "init: #{@address}, #{@access_id}, #{@access_secret}"
  end
end

# This class will maintain connection with repository
class R2Repo

  @last_domain = ""
  @repo_config = ""
  @repo = ""
  
  def open_repo
    @repo = RightAws::SdbInterface.new(@repo_config.access_id,
                                       @repo_config.access_secret,
                                       {:server => @repo_config.address})
  end

  def initialize(cfg)
    @repo_config = cfg
    open_repo
  end

  # function allowing object registration in repository
  def add(domain, item, attributes)

    _new_domain = domain

    # do not try to create domain if you have worked with it last time already
    if @last_domain != _new_domain
      @last_domain = _new_domain
      @repo.create_domain(_new_domain) 
      @repo.put_attributes(_new_domain,item,attributes)
    end
    
  end

  # function allowing object un-registration from repository
  def delete(domain, item)
    @repo.delete_attributes(domain,item)
  end

  # function 
  def list(domain)
    _items = @repo.query(domain,"*")
  end

end

module AnalyzeCmd extend OptiFlagSet

  optional_flag "add" do
    alternate_forms "a"
    description "Add an item with specified attributes to a domain."
    arity 3 # we expect <domain> <item> <attributes>
  end 

  optional_flag "update" do
    alternate_forms "u"
    description  "Add an item with specified attributes to a domain."
    arity 3 # we expect <domain> <item> <attributes>
  end

  optional_flag "delete" do
    alternate_forms "d"
    description "Delete specified item from a domain."
    arity 2 # we expect <domain> <item>
  end

  optional_flag "list" do
    alternate_forms "l"
    description "List all items in a domain."
    arity 1 # we expect <domain>
  end

  optional_flag "address" do
    description "Repository address, e.g. AWS SDB endpoint"
    alternate_forms "a"
  end

  optional_flag "id" do
    description "Access id/key to authenticate against repository, e.g. AWS access key"
    alternate_forms "i"
  end

  optional_flag "secret" do
    description "Secret key to authenticate against repositoru, e.g. AWS secret key"
    alternate_forms "s"
  end

  optional_flag "config" do
    alternate_forms "c"
    description "Configuration file."
    default "/etc/reg2rep.conf"
  end

  optional_switch_flag "help"

  and_process!

end

def show_help
  puts "reg2rep v"+VER+" - Register to repository - (c) 2010 Vanilladesk Ltd."
  puts ""
  puts "Usage: reg2rep <command> <command_params> [options]" 
  puts "Command can be"
  puts " --add     - add an item with specified attributes to domain"
  puts "             requires <domain> <item> <attributes>"
  puts " --delete  - delete specified item from domain"
  puts "             requires <domain> <item>"
  puts " --list    - list all items in domain"
  puts"              requires <domain>"
  puts " --update  - update attribute(s) of an item in domain"
  puts "             requires <domain> <item> <attributes>"
  puts " --help    - show this help"
  puts ""
  puts "Command parameters:"
  puts " domain    - domain name 'table name'"
  puts " item      - item name 'record identifier'"
  puts " attributes- list of attribute pairs separated by semi-colon ';'"
  puts "             'column values'"
  puts ""
  puts "Options:"
  puts " --config  - repository configuration file"
  puts " --address - repository address - overrides the one specified in"
  puts "             configuration file"
  puts " --id      - access id used to identify against repository - overrides"
  puts "             the one specified in configuration file"
  puts " --secret  - secret key used to authenticate against repository "
  puts "             overrides the one stored in configuration file"
  puts ""
end

class Array
  def to_h
    arr = self.dup
    #check if we have key-value pairs
    if arr.size % 2 == 0
        Hash[*arr]
    else
        Hash[*arr << nil]
    end
  end
end

def str2hash(s)
  # it is assumed that 's' is formatted as follows:
  # 'key1:value1;key2:value2...'
  a = []
  s.split(';').each{|ss| a << ss.split(':')}
  a.flatten.to_h
end

begin
  VER = '0.1'
  _cfg = R2Config.new(ARGV.flags.config, 
                      ARGV.flags.address? ? ARGV.flags.address : :nil,
                      ARGV.flags.id? ? ARGV.flags.id : :nil,
                      ARGV.flags.secret? ? ARGV.flags.secret : :nil)

  _repo = R2Repo.new(_cfg)

  begin
    if ARGV.flags.help?
      show_help
      exit 1
    end

    # command 'add' specified?
    if ARGV.flags.add?
      # we expect domain, item and attributes to be specified
      if ARGV.flags.add.length < 3
        puts "Error: Arguments missing for command '--add'"
        exit 1
      end
      _repo.add(ARGV.flags.add[0], ARGV.flags.add[1], str2hash(ARGV.flags.add[2]))
    end
 
    # command 'delete' specified
    if ARGV.flags.delete?
      # we expect domain and item to be specified
      if ARGV.flags.delete.length < 2
        puts "Error: Arguments missing for command '--delete'"
        exit 1
      end
      _repo.delete(ARGV.flags.delete[0], ARGV.flags.delete[1])
    end

    # command 'list' specified
    if ARGV.flags.list?
      # we expect domain to be specified
      if ARGV.flags.delete.list.length < 1
        puts "Error: Arguments missing for command '--list'"
        exit 1
      end
      _repo.list(ARGV.flags.list.is_a? ? ARGV.flags.list[0] : ARGV.flags.list)
    end

  end
end


#! /usr/ruby
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

ERR_START	= 1
ERR_PARAMS	= 2
ERR_REPO	= 3

begin
  require 'right_aws'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the right_aws.  Run \'gem install right_aws\' and try again.")
  exit ERR_START
end

begin
  require 'optiflag'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the optiflag.  Run \'gem install optiflag\' and try again.")
  exit ERR_START
end

begin
  require 'parseconfig'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the parseconfig.  Run \'gem install parseconfig\' and try again.")
  exit ERR_START
end

#*********************************************
# Class for config file manipulation

class R2Config
  
  #-----------------------------------
  # repository address (e.g. EC2 endpoint)
  def address
    @address
  end

  #-----------------------------------
  # repository access id (e.g. EC2 access key or other repo login name)
  def access_id
    @access_id
  end

  #-----------------------------------
  # repository access secret (e.g. EC2 secret key or other repo password)
  def access_secret
    @access_secret
  end

  #------------------------------------
  # log file
  def log_file
    @logfile
  end

  # ----------------------------------
  # verbose
  def verbose
    @verbose
  end

  #------------------------------------
  # load configuration from file
  def load(f)
    begin
      _cfg = ParseConfig.new(f)
    rescue Errno::ENOENT 
      STDERR.puts "Error: The config file #{f} was not found"
      exit ERR_PARAMS
    rescue Errno::EACCES 
      STDERR.puts "Error: The config file #{f} is not readable"
      exit ERR_PARAMS
    end

    _p = _cfg.get_params
    
    @address = _cfg.get_value('repository_address')
    @access_id = _cfg.get_value('repository_access_id')
    @access_secret = _cfg.get_value('repository_access_secret')

    @logfile = _cfg.get_value('log_file')
	@logfile = "~/reg2rep.log" if @logfile.nil?

    @verbose = _cfg.get_value('verbose_level')
	@verbose = '4' if @verbose.nil?
	
  end

  #----------------------------------
  def initialize(f,cmd_opt)
    
    load(f) if not f.nil?

    # if specified, override specified settings
    @address = cmd_opt[:flg_address] if cmd_opt.has_key?(:flg_address)
    @access_id = cmd_opt[:flg_id] if cmd_opt.has_key?(:flg_id)
    @access_secret = cmd_opt[:flg_secret] if cmd_opt.has_key?(:flg_secret)
    @logfile = cmd_opt[:flg_logfile] if cmd_opt.has_key?(:flg_logfile)
    @verbose = cmd_opt[:flg_verbose] if cmd_opt.has_key?(:flg_verbose)
  end
end

#***************************************************
# This class will maintain connection with repository
class R2Repo

  @last_domain = ""
  @repo_config = ""
  @repo = :nil
  @logger = :nil
  
  #---------------------------------
  def open_repo
    @repo = RightAws::SdbInterface.new(@repo_config.access_id,
                                       @repo_config.access_secret,
                                       {:server => @repo_config.address,
                                        :logger => @logger})
  end

  #----------------------------------
  def initialize(cfg,log)
    @repo_config = cfg
    @logger = log
    open_repo
  end

  #----------------------------------
  # function allowing object registration in repository
  def add(domain, item, attributes)

    _response = []

    @logger.info("Adding #{item} to domain #{domain}")
    @logger.debug("Attributes: #{attributes}")

    _new_domain = domain

    # do not try to create domain if you have worked with it last time already
    if @last_domain != _new_domain
      @last_domain = _new_domain
      @repo.create_domain(_new_domain) 
      begin
        @repo.put_attributes(_new_domain, item, attributes)
        @logger.debug(_response)
        @logger.info("Item added")
      rescue Exception => e
        # errors are logged in logfile
        @logger.error("Error occured: #{e.message}")
        exit ERR_REPO
      end
    end

    _response
    
  end

  #----------------------------------
  # function for updating existing record in registry
  def update(domain, item, attributes)

    _response = []

    @logger.info("Updating #{item} in domain #{domain}")
    @logger.debug("Attributes: #{attributes}")
    begin
      _response = @repo.put_attributes(domain,item,attributes)
      @logger.debug(_response)
      @logger.info("Item updated")
    rescue Exception => e
      # errors are logged in logfile
      @logger.error("Error occured: #{e.message}")
      exit ERR_REPO
    end

    _response

  end

  #----------------------------------
  # function allowing object un-registration from repository
  def delete(domain, item)

    _response = []

    @logger.info("Deleting item #{item} from domain #{domain}")
    begin
      @repo.delete_attributes(domain,item)
      @logger.debug(_response)
      @logger.info("Item deleted")
    rescue Exception => e
      # errors are logged in logfile
      @logger.error("Error occured: #{e.message}")
      exit ERR_REPO
    end

    _response

  end

  #-----------------------------------
  # function 
  def list(domain)
    _query = "select * from #{domain}"

    @logger.info("Listing all items from domain #{domain}")
    @logger.debug("Query: #{_query}")

    begin
      _items = @repo.select(_query)
      @logger.debug(_items)
      @logger.info("Items returned: #{_items.fetch(:items).length}")
    rescue Exception => e
      # errors are logged in logfile
      @logger.error("Error occured: #{e.message}")
      exit ERR_REPO
    end

    _items

  end

end

#*********************************************
# Module for analyzing commandline parameters

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
    arity 2 # we expect <domain> <list-type>
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
    description "Configuration file. Default /etc/reg2rep.conf"
  end

  optional_flag "logfile" do
    alternate_forms "o"
    description "Log file. Default STDERR."
  end

  optional_flag "verbose" do
    alternate_forms "v"
    description "Verbose level. Default 4 - info."
    value_matches [ "verbose level should be <1..5>" , /^[1-5]$/ ]
  end

  optional_switch_flag "help"

  and_process!

end

#**************************************
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
  puts "             requires <domain> <type>"
  puts "             <type> can be one of: items, table, hash"
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
  puts " --logfile - logfile. Default is STDERR."
  puts " --verbose - verbose level. Default is 4."
  puts "             1 - fatal errors"
  puts "             2 - errors"
  puts "             3 - warnings"
  puts "             4 - info"
  puts "             5 - debug"
  puts ""
end

#****************************************
# extend class Array by adding method "to_h" for conversion
# of an array to hash

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

#****************************************
# function for converting special string to hash

def str2hash(s)
  # it is assumed that 's' is formatted as follows:
  # 'key1:value1;key2:value2...'
  a = []
  s.split(';').each{|ss| a << ss.split(':')}
  a.flatten.to_h
end

#****************************************
#

def rs2table(rs)
  _t = []
  # get list of all potential attributes
  _a = ['#']
  rs.each do |row|
    row.each_pair do |item, attrs|
	  _a = _a | attrs.keys
	end
  end
  
  _t << _a
  
  _r = Array.new(_a.length)
  
  rs.each do |row| 
    row.each_pair do |item, attrs|
	  _r[0] = item
	  attrs.each_pair do |k,v|
            if v.kind_of? Array
              #AWS SimpleDB is storing attribute changes in sequence
 	      _r[_a.index(k)] = v[v.length-1].to_s if v.length > 0
            else
              _r[_a.index(k)] = v.to_s
            end
	  end
	end
	_t << _r
	
	_r = Array.new(_a.length)
  end
  _t
end

#****************************************
def print_table(t, delim = '|')
  t.each do |row|
    STDOUT.puts row * delim
  end
end

#****************************************
def print_hash(rs, delim = '|')
  s = ""
  rs.each do |row| 
    row.each_pair do |item, attrs|
	  s << item << delim
	  attrs.each_pair do |k,v|
            
	    s << k << '=>' 
            if v.kind_of? Array
              s << v[v.length-1].to_s if v.length > 0
            else
              s << v.to_s
            end
            s << delim
	  end
	end
	STDOUT.puts(s)
	s = ""
  end

end

#****************************************
def print_items(rs)
  s = ""
  rs.each do |row| 
    row.each_pair do |item, attrs|
	  s << item
	end
	STDOUT.puts(s)
	s = ""
  end

end

#****************************************

def hide_secret(s)
  _p = s.length/10
  s.slice(0,_p) + "xxxxxx" + s.slice(s.length-_p,s.length)
end

#****************************************

begin
  VER = '0.1'

  # create hash containing commandline options, if there are any  

  _cfg_params = []
  _cfg_params << [:flg_address, ARGV.flags.address] if ARGV.flags.address?
  _cfg_params << [:flg_id, ARGV.flags.id] if ARGV.flags.id?
  _cfg_params << [:flg_secret, ARGV.flags.secret] if ARGV.flags.secret?
  _cfg_params << [:flg_logfile, ARGV.flags.logfile] if ARGV.flags.logfile?
  _cfg_params << [:flg_verbose, ARGV.flags.verbose] if ARGV.flags.verbose?

  _cfg = R2Config.new(ARGV.flags.config, Hash[*_cfg_params.flatten])

  begin
    if ARGV.flags.help?
      show_help
      exit ERR_START
    end

    _log = Logger.new(STDERR)

    _log.level = case _cfg.verbose
      when '1' then Logger::FATAL
      when '2' then Logger::ERROR
      when '3' then Logger::WARNING
      when '4' then Logger::INFO
      when '5' then Logger::DEBUG
      else Logger::INFO
    end

    # check configuration
    if _cfg.access_id.nil? || _cfg.address.nil? || _cfg.access_secret.nil?
      STDERR.puts "Error: Repository address and/or credentials are missing."
      puts _cfg.address
      puts _cfg.access_id
      puts _cfg.access_secret
      exit ERR_PARAMS
    end
 
    # command 'add' specified?
    if ARGV.flags.add?
      # we expect domain, item and attributes to be specified
      if not ARGV.flags.add.kind_of? Array || ARGV.flags.add.length < 3
        STDERR.puts "Error: Arguments missing for command '--add'"
        exit ERR_PARAMS
      end
    end

    # command 'update' specified?
    if ARGV.flags.update?
      # we expect domain, item and attributes to be specified
      if not ARGV.flags.update.kind_of? Array || ARGV.flags.update.length < 3
        STDERR.puts "Error: Arguments missing for command '--update'"
        exit ERR_PARAMS
      end
    end


    # command 'delete' specified
    if ARGV.flags.delete?
      # we expect domain and item to be specified
      if not ARGV.flags.delete.kind_of? Array || ARGV.flags.delete.length < 2
        STDERR.puts "Error: Arguments missing for command '--delete'"
        exit ERR_PARAMS
      end
    end

    # command 'list' specified
    if ARGV.flags.list?
      # we expect domain to be specified
      if not ARGV.flags.list.kind_of? Array || ARGV.flags.list.length < 2
        STDERR.puts "Error: Arguments missing for command '--list'"
        exit ERR_PARAMS
      end
    end

    if _cfg.log_file != :nil
      begin
        _log = Logger.new(_cfg.log_file)
      rescue
        STDERR.puts "Error: Not possible to create/open log file #{_cfg.log_file}"
        exit ERR_PARAMS
      end
    end

	
    _log.info("******** reg2rep #{VER} started")
    _log.info("repository: #{_cfg.address}")
    _log.info("access id: #{_cfg.access_id}")
    _log.info("secret key: " + hide_secret(_cfg.access_secret))
    _log.info("verbose: #{_cfg.verbose}")

    _repo = R2Repo.new(_cfg, _log)

    # command 'add' specified?
    if ARGV.flags.add?
      _result = _repo.add(ARGV.flags.add[0], ARGV.flags.add[1], str2hash(ARGV.flags.add[2]))
      STDOUT.puts("Item #{ARGV.flags.add[1]} added to domain #{ARGV.flags.add[0]}")	  
    end

     # command 'update' specified?
    if ARGV.flags.update?
      _result = _repo.update(ARGV.flags.update[0], ARGV.flags.update[1], str2hash(ARGV.flags.update[2]))
      STDOUT.puts("Item #{ARGV.flags.update[1]} updated in domain #{ARGV.flags.update[0]}")	  
    end
 
    # command 'delete' specified
    if ARGV.flags.delete?
      _result = _repo.delete(ARGV.flags.delete[0], ARGV.flags.delete[1])
	  STDOUT.puts("Item #{ARGV.flags.delete[1]} deleted from domain #{ARGV.flags.delete[0]}")
    end

    # command 'list' specified
    if ARGV.flags.list?
      _log.info("listing items in domain #{ARGV.flags.list[0]} showing #{ARGV.flags.list[1]}")
      _result = _repo.list(ARGV.flags.list[0])
	  
	  if ARGV.flags.list[1] == "items"
	    print_items(_result.fetch(:items))
	  elsif ARGV.flags.list[1] == "table"
	    print_table(rs2table(_result.fetch(:items)))
	  else
	    print_hash(_result.fetch(:items))
	  end
    end
    _log.close
	
  end
end


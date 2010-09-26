#!/usr/ruby
#################################
# 
# Reg2Rep is a tool allowing you to register/un-register 
# and check registration status of any object in central
# repository.
# 
# This script depends on following gems:
# - right_aws
# - right_http_connection
# - optiflag
# - parseconfig
#
# Copyright (c) 2010 Vanilladesk Ltd. http://www.vanilladesk.com
#
# Repository: http://github.com/vanilladesk/reg2rep
#
#################################

ERR_START	= 1
ERR_PARAMS	= 2
ERR_REPO	= 3

begin
  require 'rubygems'
rescue LoadError => e
  STDERR.puts("Library 'rubygems' required. Read http://docs.rubygems.org/read/chapter/3#page13 how to install it.")
  exit ERR_START
end

begin
  require 'logger'
rescue LoadError => e
  STDERR.puts("Library 'logger' not found.")
  exit ERR_START
end

begin
  require 'right_aws'
rescue LoadError => e
  STDERR.puts("Library 'right_aws' not found.  Run \'gem install right_aws\' and try again.")
  exit ERR_START
end

begin
  require 'optiflag'
rescue LoadError => e
  STDERR.puts("Library 'optiflag' not found.  Run \'gem install optiflag\' and try again.")
  exit ERR_START
end

begin
  require 'parseconfig'
rescue LoadError => e
  STDERR.puts("Library 'parseconfig' not found.  Run \'gem install parseconfig\' and try again.")
  exit ERR_START
end

#*********************************************
# Class for config file manipulation

class R2Config
  
  #-----------------------------------
  
  attr_accessor :address		# repository address (e.g. EC2 endpoint)
  attr_accessor :access_id		# repository access id (e.g. EC2 access key or other repo login name)
  attr_accessor :access_secret	# repository access secret (e.g. EC2 secret key or other repo password)
  attr_accessor :log_file		# log file
  attr_accessor :verbose		# verbose level
  attr_accessor :query			# query to be used for getting the list of items
  
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
    @log_file = _cfg.get_value('log_file')
    @verbose = _cfg.get_value('verbose_level')
    @query = _cfg.get_value('query')
	
  end

  #----------------------------------
  def initialize(f,cmd_opt)

    # load configuration from a file
    load(f) if not f.nil?

    # set defaults if not set in configuration file
    @verbose = '4' if @verbose.nil?
    @query = 'select * from %domain%' if @query.nil?

    # if specified, override specified settings
    @address = cmd_opt[:flg_address] if cmd_opt.has_key?(:flg_address)
    @access_id = cmd_opt[:flg_id] if cmd_opt.has_key?(:flg_id)
    @access_secret = cmd_opt[:flg_secret] if cmd_opt.has_key?(:flg_secret)
    @log_file = cmd_opt[:flg_logfile] if cmd_opt.has_key?(:flg_logfile)
    @verbose = cmd_opt[:flg_verbose] if cmd_opt.has_key?(:flg_verbose)
    @query = cmd_opt[:flg_query] if cmd_opt.has_key?(:flg_query)

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
        _response = @repo.put_attributes(_new_domain, item, attributes, true)
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
      _response = @repo.put_attributes(domain, item, attributes, true)
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
  def list(domain, query = @repo_config.query)
    query = @repo_config.query if query.nil?
    _query = query.gsub(/%domain%/, domain)

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

  #----------------------------------
  # function allowing object un-registration from repository
  def deletedomain(domain)

    _response = []

    @logger.info("Deleting domain #{domain}")
    begin
      @repo.delete_domain(domain)
      @logger.debug(_response)
      @logger.info("Domain deleted")
    rescue Exception => e
      # errors are logged in logfile
      @logger.error("Error occured: #{e.message}")
      exit ERR_REPO
    end

    _response

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

  optional_flag "deletedomain" do
    alternate_forms "dd"
    description "Delete specified domain."
    arity 1 # we expect <domain>
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

  optional_flag "query" do
    alternate_forms "q"
    description "Query to get list of items from the domain. Default 'select * from <domain>'."
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
  puts ""
  puts "Commands:"
  puts " --add            - Add an item with specified attributes to a domain."
  puts "                    Requires <domain> <item> <attributes>"
  puts " --delete         - Delete specified item from a domain."
  puts "                    Requires <domain> <item>"
  puts " --deletedomain   - Delete specified domain."
  puts "                    Requires <domain>"
  puts " --list           - List all items in domain."
  puts "                    Requires <domain> <type>"
  puts "                    <type> can be one of: items, table, hash, items-flat"
  puts " --update         - Update attribute(s) of an item in domain."
  puts "                    Requires <domain> <item> <attributes>"
  puts " --help           - Show this help"
  puts ""
  puts "Command parameters:"
  puts " domain           - Domain name 'table name'"
  puts " item             - Item name 'record identifier'"
  puts " attributes       - List of attribute pairs separated by semi-colon ';'"
  puts "                    'column values'"
  puts ""
  puts "Options:"
  puts " --config         - Repository configuration file."
  puts " --address        - Repository address."
  puts " --id             - Access id/login used to identify against repository"
  puts " --secret         - Secret key/password used to authenticate against repository."
  puts " --query          - Query to obtain list of items - meaningful with --list" 
  puts "                    command only, ignored otherwise."
  puts "                    Default query is 'select * from %domain%'. Macro %domain%,"
  puts "                    if used, will be replaced with provided domain name."
  puts " --logfile        - Logfile. Default is STDERR."
  puts " --verbose        - Verbose level. Default is 4."
  puts "                    1 - fatal errors"
  puts "                    2 - errors"
  puts "                    3 - warnings"
  puts "                    4 - info"
  puts "                    5 - debug"
  puts ""
  puts "Note: All options specified as command line option override the same"
  puts "      options specified in configuration file." 
  puts ""
end

#****************************************
# extend class Array by adding method "to_h" for 

class Array
  def to_h
    # conversion of an array to hash
	
    _arr = self.dup
	
    #check if we have key-value pairs
    if _arr.size % 2 == 0
        Hash[*_arr]
    else
        Hash[*_arr << nil]
    end
  end
end

#****************************************
# Extend class String

class String

  def to_h
    # Conversion of a string to a hash.
    # It is assumes that string is formatted as follows: 'key1:value1;key2:value2...'

    _a = []
	_s = self.dup
	
    _s.split(';').each{|ss| _a << ss.split(':')}
    _a.flatten.to_h
	
  end
  
  #---------------------
  
  def to_secret(c = '*')
    # Replaces/Hides middle 80% of a string with specified character
	
	_s = self.dup
    _p = _s.length/10
	
    _s.slice(0, _p) + "".ljust(_s.length-(2*_p), c) + _s.slice(_s.length - _p, _s.length)
	
  end
  
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

def print_items(rs, format = :list)
  # format :list will print items each on separate line
  # format :flat will create comma separated list of items
  _s = ""
  _r = 0
  rs.each do |row|
    _r = _r + 1
    row.each_pair do |item, attrs|
          _s << item
		  
		  # use pipe to separate attributes at one row
          _s << "|" if row.length > 1
		  
        end
        if format == :list
          STDOUT.puts(_s)
          _s = ""
        end

        # use comma to separate items in case format is :flat
		_s << "," if format == :flat && rs.length > _r
  end
  STDOUT.puts(_s) if format == :flat

end


#****************************************

begin
  VER = '1.0.0'
  GLB_CFG = '/etc/reg2rep/reg2rep.conf'
  
  # define configuration file to use
  if ARGV.flags.config?
    _cfile = ARGV.flags.config
  elsif File::exists?( GLB_CFG )
    _cfile = GLB_CFG
  end

  # create hash containing commandline options, if there are any  

  _cfg_params = {}
  _cfg_params[:flg_address] = ARGV.flags.address if ARGV.flags.address?
  _cfg_params[:flg_id] = ARGV.flags.id if ARGV.flags.id?
  _cfg_params[:flg_secret] = ARGV.flags.secret if ARGV.flags.secret?
  _cfg_params[:flg_logfile] = ARGV.flags.logfile if ARGV.flags.logfile?
  _cfg_params[:flg_verbose] = ARGV.flags.verbose if ARGV.flags.verbose?
  _cfg_params[:flg_query] = ARGV.flags.query if ARGV.flags.query?

  _cfg = R2Config.new(_cfile, _cfg_params)

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
      exit ERR_PARAMS
    end
 
    # command 'add' specified?
    if ARGV.flags.add?
      # we expect domain, item and attributes to be specified
      if (not ARGV.flags.add.kind_of? Array) || ARGV.flags.add.length < 3
        STDERR.puts "Error: Arguments missing for command '--add'"
        exit ERR_PARAMS
      end
    end

    # command 'update' specified?
    if ARGV.flags.update?
      # we expect domain, item and attributes to be specified
      if (not ARGV.flags.update.kind_of? Array) || ARGV.flags.update.length < 3
        STDERR.puts "Error: Arguments missing for command '--update'"
        exit ERR_PARAMS
      end
    end

    # command 'delete' specified
    if ARGV.flags.delete?
      # we expect domain and item to be specified
      if (not ARGV.flags.delete.kind_of? Array) || ARGV.flags.delete.length < 2
        STDERR.puts "Error: Arguments missing for command '--delete'"
        exit ERR_PARAMS
      end
    end

   # command 'list' specified
    if ARGV.flags.list?
      # we expect domain to be specified
      if (not ARGV.flags.list.kind_of? Array) || ARGV.flags.list.length < 2
        STDERR.puts "Error: Arguments missing for command '--list'"
        exit ERR_PARAMS
      end
    end

    if not _cfg.log_file.nil?
      begin
        _log = Logger.new(_cfg.log_file)
      rescue
        STDERR.puts "Error: Not possible to create/open log file #{_cfg.log_file}"
        exit ERR_PARAMS
      end
    end
	
	#---------------------------------
	
    _log.info("******** reg2rep #{VER} started")
    _log.info("configuration file: #{_cfile}")
    _log.info("repository: #{_cfg.address}")
    _log.info("access id: #{_cfg.access_id}")
    _log.info("secret key: " + _cfg.access_secret.to_secret)
    _log.info("verbose: #{_cfg.verbose}")

    _repo = R2Repo.new(_cfg, _log)

    # command 'add' specified?
    if ARGV.flags.add?
      _result = _repo.add(ARGV.flags.add[0], ARGV.flags.add[1], ARGV.flags.add[2].to_h)
	    STDOUT.puts("Item #{ARGV.flags.add[1]} added to domain #{ARGV.flags.add[0]}")	if _cfg.verbose == 5
    end

     # command 'update' specified?
    if ARGV.flags.update?
      _result = _repo.update(ARGV.flags.update[0], ARGV.flags.update[1], ARGV.flags.update[2].to_h)
      STDOUT.puts("Item #{ARGV.flags.update[1]} updated in domain #{ARGV.flags.update[0]}")	if _cfg.verbose == 5
    end
 
    # command 'delete' specified
    if ARGV.flags.delete?
      _result = _repo.delete(ARGV.flags.delete[0], ARGV.flags.delete[1])
      STDOUT.puts("Item #{ARGV.flags.delete[1]} deleted from domain #{ARGV.flags.delete[0]}") if _cfg.verbose == 5
    end

   # command 'deletedomain' specified
    if ARGV.flags.deletedomain?
      _result = _repo.deletedomain(ARGV.flags.deletedomain)
      STDOUT.puts("Domain #{ARGV.flags.deletedomain} deleted") if _cfg.verbose == 5
    end

    # command 'list' specified
    if ARGV.flags.list?
      _log.info("listing items in domain #{ARGV.flags.list[0]} showing #{ARGV.flags.list[1]}")
      _result = _repo.list(ARGV.flags.list[0], ARGV.flags.query)
	  
	  if ARGV.flags.list[1] == "items"
	    print_items(_result.fetch(:items), :list)
	  elsif ARGV.flags.list[1] == "items-flat"
	    print_items(_result.fetch(:items), :flat)
	  elsif ARGV.flags.list[1] == "table"
	    print_table(rs2table(_result.fetch(:items)))
	  else
	    print_hash(_result.fetch(:items))
	  end
    end
	
    _log.close
	
  end
end


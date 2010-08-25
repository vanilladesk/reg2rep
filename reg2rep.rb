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
  exit
end

begin
  require 'optiflag'
rescue LoadError => e
  STDERR.puts("Reg2Rep requires the optiflag.  Run \'gem install optiflag\' and try again.")
  exit
end

class R2Config
  
  # repository address (e.g. EC2 endpoint)
  def repo_address
    @repo_address
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
  def load(f : String)
    @repo_address = 'sdb.eu-west-1.amazonaws.com'
    @access_id = 'huhuhuhu'
    @access_secret = 'hehehehe'
  end

  def initialize(f : String)
    load(f)
  end

end

# This class will maintain connection with repository
class R2Repo

  @last_domain = ""
  @repo_config = ""
  @repo = ""
  
  def open_repo
    @repo = RightAws::SdbInterface.new(@repo_config.access_id.as_s,
                                       @repo_config.access_secret.as_s,
                                       {:server => @repo_config.address.as_s})
  end

  def create_sys_domain(system : String, environment : String, domain : String)
    system + environment + domain
  end

  def initialize(cfg : R2Config)
    @repo_config = cfg
    open_repo
  end

  # function allowing object registration in repository
  def register(system : String, 
               environment : String, 
               domain : String, 
               item : String, 
               attributes : Hash)

    _new_domain = create_sys_domain(system, environment, domain)

    # do not try to create domain if you have worked with it last time already
    if @last_domain != _new_domain
      @last_domain = _new_domain
      @repo.create_domain(_new_domain.as_s) 
      @repo.put_attributes(_new_domain.as_s,item.as_s,attributes)
    end
    
  end

  # function allowing object un-registration from repository
  def unregister(system : String, environment : String, domain : String, item : String)
    @repo.delete_attributes(create_sys_domain(system,environment,domain),item.as_s)
  end

  # function 
  def get_registrations(system : String, environment : String, domain : String)
    _items = @repo.query(create_sys_domain(system,environment,domain),"*")
  end

end

module AnalyzeCmd extend OptiFlagSet
  optional_flag "add" do
    alternate_forms "a"
    arity 3 # we expect <domain> <item> <attributes>
  end 

  optional_flag "update" do
    alternate_forms "u"
    arity 3 # we expect <domain> <item> <attributes>
  end

  optional_flag "delete" do
    alternate_forms "d"
    arity 2 # we expect <domain> <item>
  end

  optional_flag "list" do
    alternate_forms "l"
    arity 1 # we expect <domain>
  end

  optional_flag "address" do
    alternate_forms "a"
  end

  optional_flag "id" do
    alternate_forms "i"
  end

  optional_flag "secret" do
    alternate_forms "s"
  end

  optional_flag "config" do
    alternate_forms "c"
    default "/etc/reg2rep.conf"
  end

  usage_flag "help", "h"

end

def show_help(msg)
  puts "reg2rep v"+ver+" - Register to repository - (c) 2010 Vanilladesk Ltd."
  puts msg
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

begin
  ver='0.1'
  args = read_cmd_parameters
  if args[:result] == false
    show_help(args[:message])
    exit 1
  else
   
  end
  

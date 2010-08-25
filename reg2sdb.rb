#! /bin/ruby
#################################
# 
# Reg2SDB is a tool allowing you to register/un-register 
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
  STDERR.puts("Reg2SDB requires the right_aws.  Run \'gem install right_aws\' and try again.")
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

  def initialize
    @repo_address = 'sdb.eu-west-1.amazonaws.com'
    @access_id = 'huhuhuhu'
    @access_secret = 'hehehehe'
  end

end

# This class will maintain connection with repository
class R2Connect2Repo
  
  def initialize(r_address, r_access_id, r_access_scr)
    @repo_address = r_address
    @repo_access_id = r_access_id
    @repo_access_secret = r_access_scr
  end

end

# function allowing object registration in repository
def register_to_repo(system, environment, domain, item, attributes)
end

# function allowing object un-registration from repository
def unregister_from_repo(system, environment, domain, item)
end

# function 
def get_registrations(system, environment, domain)
end



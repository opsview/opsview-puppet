#   Copyright 2017 Opsview Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

begin
  require 'rest-client'
  require 'json'
  require 'yaml'
rescue LoadError => e
  nil
end

class Puppet::Provider::Opsview < Puppet::Provider

  #Class variables

  #The first bit of @@errors tracks token creation
  #
  API_TOKEN_ERROR_MASK = 0b00000000000000001
  API_CONFIGURATION_ERROR_MASK = 0b11111111111111110
  API_MINIMUM_VERSION = 5.3
  @@errors = 0
  @@opsview_classvars = {
        :token => '',
	:config => {},
        :calculated_total => 0,
        :total => 0,
        :seen => 0,
        :forked => false,
        :reload_opsview => false,
        :sleeptime => 10,
        :api_version => 0
  }

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
  end
  
  def destroy
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    @property_hash[:ensure] != :absent
  end

  private

  def internal
          if @@opsview_classvars[:calculated_total] == 0 && defined? resource.catalog.resources
                  [
                   Puppet::Type.type(:opsview_bsmcomponent),
                   Puppet::Type.type(:opsview_bsmservice),
                   Puppet::Type.type(:opsview_contact),
                   Puppet::Type.type(:opsview_hashtag),
                   Puppet::Type.type(:opsview_host),
                   Puppet::Type.type(:opsview_hostcheckcommand),
                   Puppet::Type.type(:opsview_hostgroup),
                   Puppet::Type.type(:opsview_notificationmethod),
                   Puppet::Type.type(:opsview_notificationprofile),
                   Puppet::Type.type(:opsview_role),
                   Puppet::Type.type(:opsview_servicecheck),
                   Puppet::Type.type(:opsview_servicegroup),
                   Puppet::Type.type(:opsview_tenancy),
                   Puppet::Type.type(:opsview_timeperiod),
                   Puppet::Type.type(:opsview_variable)
                  ].each do |type|
                        @@opsview_classvars[:total] += resource.catalog.resources.find_all{ |x| x.is_a?(type) }.count
                  end
                  @@opsview_classvars[:calculated_total] = 1
        end

        @@opsview_classvars[:seen] += 1

	#We know when we are on the last Opsview-related object to be processed, but we don't know
	#if we will need to flush it.  We will do a delayed reload to give the final object enough time
	#to process.
        if (@@opsview_classvars[:seen] == @@opsview_classvars[:total]) && @@opsview_classvars[:reload_opsview] == true
                Puppet.notice "Forking a process to reload Opsview in #{@@opsview_classvars[:sleeptime]} seconds"
                @@opsview_classvars[:forked] = true
                fork do 
                        sleep(@@opsview_classvars[:sleeptime])
                        self.class.actually_reload_opsview
                        exit
                end
        end
  end

  #Read in the configuration of Opsview to get the REST API URL and user credentials
  def self.read_config
    config_file = "/etc/puppet/opsview.conf"
    Puppet.debug "Reading Opsview configuration file located at #{config_file}"

    begin
      conf = YAML.load_file(config_file)
    rescue
      raise Puppet::ParseError, "Could not parse YAML configuration file " + config_file + " " + $!.inspect
    end

    if conf["username"].nil? or conf["password"].nil? or conf["url"].nil?
      raise Puppet::ParseError, "Config file must contain URL, username, and password fields."
    end

    conf
  end

  #Store the Opsview configuration into a class variable, if needed, and return the URL and user credentials for the REST API
  def self.config
    if @@opsview_classvars[:config].empty?
      @@opsview_classvars[:config] = read_config 
    end
    @@opsview_classvars[:config]
  end

  #Generate a new REST API token
  def self.retrieve_token
    Puppet.debug "Retrieving Opsview token"
    post_body = { "username" => config["username"],
                  "password" => config["password"] }.to_json

    url = [ config["url"], "login" ].join("/")

    Puppet.debug "Using Opsview url: "+url
    Puppet.debug "using post: username:"+config["username"]+" password:"+config["password"].gsub(/./,'x')

    if Puppet[:debug]
      Puppet.debug "Logging REST API calls to: /tmp/puppet_restapi.log"
      RestClient.log='/tmp/puppet_restapi.log'
    end

    begin
      response = RestClient.post url, post_body, :content_type => :json
    rescue
      @@errors |= API_TOKEN_ERROR_MASK
      Puppet.warning "Problem retrieving token from Opsview server; " + $!.inspect
      return
    end

    case response.code
    when 200
      Puppet.debug "Successfully logged in: Response code: 200"
    else
      Puppet.warning "Unable to log in to Opsview server; HTTP code " + response.code
      @@errors |= API_TOKEN_ERROR_MASK
      return
    end

    received_token = JSON.parse(response)['token']
    Puppet.debug "Received token: "+received_token
    received_token
  end

  def self.token
    if @@opsview_classvars[:token].empty?
      @@opsview_classvars[:token] = retrieve_token
    end

    @@opsview_classvars[:token]
  end

  #As the name suggests, fail if there have been any issues generating an Opsview token
  def self.fail_if_token_error
    #Make sure a token retrieval has been attempted first
    token
    if (@@errors & API_TOKEN_ERROR_MASK) == API_TOKEN_ERROR_MASK
      raise "Cannot query API due to token error"
    end
  end

  #Queries information from Opsview - most of the time, this is something like hosts, host groups, etc
  def self.query_api(subpath="config/#{@object_type.downcase}", skip_api_check=0, columns='+snmpinterfaces', filter='')
    fail_if_token_error
    check_api_version(API_MINIMUM_VERSION) if skip_api_check !=1 and @@opsview_classvars[:api_version] == 0
    url = [ config["url"], subpath ].join("/")

    begin
        response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:rows => :all, :include_encrypted => 1, :cols => columns, :json_filter => filter}
    rescue
      @@errors = 1
      Puppet.warning "query_api: Problem talking to Opsview server; ignoring Opsview config: " + $!.inspect
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end

    #Take into account that querying things like 'info' or 'reload' will not have a 'list' section
    if !responseJson["list"].nil?
      objs = responseJson["list"]
    else
      objs = responseJson
    end

    objs
  end

  #Verify that the Opsview server meets the required API version for the Puppet module
  def self.check_api_version(minimum=0)
    Puppet.debug "Checking API version"
    version=query_api_status  
    raise "Opsview API version too low: #{version} < #{minimum}" if (version < minimum)
  end

  #Fetch the Opsview API version
  def self.query_api_status
    if ( @@opsview_classvars[:api_version] == 0 )
      @@opsview_classvars[:api_version] = query_api("info",1)["opsview_version"].to_f
    end
    @@opsview_classvars[:api_version]
  end

  #Send configuration changes to Opsview
  def self.create_or_update_api_object(json,type=0)
    fail_if_token_error

    url = [ config["url"], "config/#{@object_type.downcase}" ].join("/")
    begin
      case type
      when 0
        response = RestClient.put url, json, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
      when 1
        response = RestClient.post url, json, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
      else
        Puppet.warning "Unknown type"
      end
    rescue
      @@errors = @@errors & API_TOKEN_ERROR_MASK | ( ( (@@errors & API_CONFIGURATION_ERROR_MASK) >> 1 ) + 1 << 1)
      raise Puppet::Error, "Could not update Opsview. You should check /var/log/opsview/opsview-web.log for more information.  " + $!.inspect + " #{json}"
    end
  end

  #Used by flush method
  def create_or_update_api_object(json,type=0)
    self.class.create_or_update_api_object(json,type)
  end
  
  def self.actually_reload_opsview
    reload_status = get_reload_status
    return if reload_status != 0

    Puppet.notice "Performing Opsview reload"
    url = [ config["url"], "reload" ].join("/")

    begin
      response = RestClient.post url, '', :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:asynchronous => 1}
    rescue
      Puppet.warning "Unable to reload Opsview: " + $!.inspect
      return
    end

  end

  #Called from flush method
  def do_reload_opsview
    self.class.do_reload_opsview
  end
  
  #Reload Opsview if we are the last object to be updated out of all Opsview objects
  def self.do_reload_opsview
    @@opsview_classvars[:reload_opsview] = true
    if (@@opsview_classvars[:seen] == @@opsview_classvars[:total]) && @@opsview_classvars[:forked] == false
        actually_reload_opsview
    end
  end

  #Determine the current status of Opsview reloads.  If there have been failed configuration updates, skip the reload
  def self.get_reload_status
    if (@@errors & API_CONFIGURATION_ERROR_MASK >> 1) > 0
      Puppet.warning "Skipping reload due to errors encountered while updating the configuration"
      return 1
    end

    last_reload = query_api("reload")

    if last_reload["configuration_status"] == "uptodate"
        Puppet.info "opsview_reload: Opsview is already up-to-date; exiting"
        return 1
    end

    if last_reload["server_status"].to_i > 0
        case last_reload["server_status"].to_i
        when 1
            Puppet.info "Opsview reload already in progress; skipping"
            return 1
        when 2
            Puppet.warning "Opsview server is not running"
            return 1
        when 3
            Puppet.warning "Opsview Server: Configuration error or critical error #{last_reload['messages']}"
            return 1
        when 4
            Puppet.warning "Warnings exist in configuration:" + last_reload["messages"].inspect
        end
    end
    return 0

  end

end

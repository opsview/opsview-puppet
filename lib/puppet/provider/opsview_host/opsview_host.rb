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

require File.join(File.dirname(__FILE__), '..', 'opsview')

begin
  require 'json'
rescue LoadError => e
  Puppet.info "You need the `json` gem for communicating with Opsview servers."
end
begin
  require 'rest-client'
rescue LoadError => e
  Puppet.info "You need the `rest-client` gem for communicating wtih Opsview servers."
end

require 'puppet'
# Config file parsing
require 'yaml'

Puppet::Type.type(:opsview_host).provide :opsview, :parent => Puppet::Provider::Opsview do
  @object_type='host'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end

  def internal=(should)
  end

  ######Start Used by flush method######
  def generic_fields
    self.class.generic_fields
  end

  def generic_blankable_fields
    self.class.generic_blankable_fields
  end

  def generic_name_fields
    self.class.generic_name_fields
  end

  def generic_array_name_fields
    self.class.generic_array_name_fields
  end

  def puppet_map
    self.class.puppet_map
  end
  ######End Used by flush method######

  ######Start Define your fields here######
  def self.generic_fields
    [:check_attempts, :check_interval, :enable_rancid, :enable_snmp, :event_handler, :event_handler_always_execute, :flap_detection, :ip, :name,
     :rancid_autoenable, :rancid_connection_type, :rancid_password, :renotification_interval, :retry_check_interval, :snmp_extended_throughput_data,
     :snmp_community, :snmp_message_size, :snmp_port, :snmp_use_getnext, :snmp_use_ifname, :snmp_version, :snmp_ifdescr_level, :snmpv3_authentication_password, :snmpv3_authentication_protocol,
     :snmpv3_privacy_password, :snmpv3_privacy_protocol]
  end

  def self.generic_blankable_fields
    [:description, :notification_options, :other_addresses, :rancid_username, :snmpv3_username]
  end

  def self.generic_name_fields
    [:check_command, :check_period, :hostgroup, :icon, :monitored_by, :notification_period, :rancid_vendor]
  end

  def self.generic_array_name_fields
    [:hashtags, :hosttemplates, :parents]
  end
  ######End Define your fields here######

  #SYNTAX for map
  #:puppet_name => "rest_api_name"
  def self.puppet_map
  {
    :description => 'alias',
    :enable_rancid => 'use_rancid',
    :event_handler_always_execute => 'event_handler_always_exec',
    :flap_detection => 'flap_detection_enabled',
    :renotification_interval => 'notification_interval',
    :rancid_password => 'encrypted_rancid_password',
    :hashtags => 'keywords',
    :snmp_community => 'encrypted_snmp_community',
    :snmp_message_size => 'snmp_max_msg_size',
    :snmp_ifdescr_level => 'tidy_ifdescr_level',
    :snmpv3_authentication_password => 'encrypted_snmpv3_authpassword',
    :snmpv3_authentication_protocol => 'snmpv3_authprotocol',
    :snmpv3_privacy_password => 'encrypted_snmpv3_privpassword',
    :snmpv3_privacy_protocol => 'snmpv3_privprotocol'

  } 
  end

  def self.object_map(object)
    p = { :name      => object["name"],
          :host => object["name"],
          :full_json => object,
          :ensure    => :present }


    #Loop through fields that do not require any special handling
    [generic_fields, generic_blankable_fields].flatten.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      p[property] = object[api_name] if defined?object[api_name]
    end

    #Loop through fields that have a name contained inside of a hash that do not require any special handling
    generic_name_fields.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      p[property] = object[api_name]["name"] if defined?object[api_name]["name"]
    end

    #Loop through an array that specifies an item based on name and does not require any other special handling
    generic_array_name_fields.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      p[property] = object[api_name].collect{ |c| c["name"]} if defined?object[api_name]
    end

    p[:servicechecks] = object["servicechecks"].collect{ |c| {"name" => c["name"], "event_handler" => c["event_handler"], "exception" => c["exception"], "timed_exception" => c["timed_exception"]}.delete_if{ |k, v| v.nil?}  } if defined?object["servicechecks"]
    p[:variables] = object["hostattributes"].collect{ |c| {"name" => c["name"], "value" => c["value"], "arg1" => c["arg1"], "arg2" => c["arg2"], "arg3" => c["arg3"], "arg4" => c["arg4"], "encrypted_arg1" => c["encrypted_arg1"], "encrypted_arg2" => c["encrypted_arg2"], "encrypted_arg3" => c["encrypted_arg3"], "encrypted_arg4" => c["encrypted_arg4"] }.delete_if{ |k, v| v.nil?}  } if defined?object["hostattributes"]
    p[:snmp_interfaces] = object["snmpinterfaces"].collect{ |c| {"interface" => c["interfacename"], "enabled" => c["active"], "discards_critical" => c["discards_critical"], "discards_warning" => c["discards_warning"], "errors_warning" => c["errors_warning"], "errors_critical" => c["errors_critical"], "throughput_critical" => c["throughput_critical"], "throughput_warning" => c["throughput_warning"] } }


    p
  end

  def self.instances
    providers = []

    objects = query_api
    objects.each do |object|
      providers << new(object_map(object))
    end

    providers
  end

  def self.prefetch(resources)
    Puppet.debug "Prefetching values from Opsview -- start"
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
    Puppet.debug "Prefetching values from Opsview -- end"
  end

  def initialize(*args)
    super

    # Copy over the json for an object that already exists in Opsview
    if args.first.class == Hash and args.first.has_key?(:full_json)
      @object_json = args.first[:full_json]
    end

    @property_hash = @property_hash.inject({}) do |result, ary|
      param, values = ary

      # Exclude parameters that are not managed from being included in @property_hash
      next result unless self.class.resource_type.validattr?(param)

      paramclass = self.class.resource_type.attrclass(param)

      #If we are not dealing with an array, simply set the value
      unless values.is_a?(Array)
        result[param] = values
        next result
      end

      #Either set the full array or only the first element based on the array_matching setting
      if paramclass.superclass == Puppet::Parameter or paramclass.array_matching == :first
        result[param] = values[0]
      else
        result[param] = values
      end

      result
    end

  end


  def flush
    Puppet.debug "Flushing object: #{@resource[:name]}"
    #If we are updating an existing object, @object_json will exist and we can use this to populate our json put/post
    if (@object_json)
      @upload_json = @object_json.dup
    else
      @upload_json = default_object
    end
    @default_json = default_object

    @upload_json["name"] = @resource[:name]

    #Loop through fields that do not need any kind of special processing
    generic_fields.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      @upload_json[api_name] = @property_hash[property] if not @property_hash[property].to_s.empty?
    end

    #Loop through fields that can take blank values
    generic_blankable_fields.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      if @property_hash[property] and not @property_hash[property].nil?
        @upload_json[api_name] = @property_hash[property]
      else
        @upload_json[api_name] = @default_json[api_name]
      end
    end

    #Loop through fields that have a name contained inside of a hash that do not require any special handling
    generic_name_fields.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      if not @property_hash[property].to_s.empty?
        @upload_json[api_name] = { 'name' => @property_hash[property] }
      else
        @upload_json[api_name] = @default_json[api_name]
      end
    end

    #Loop through an array that specifies an item based on name and does not require any other special handling
    generic_array_name_fields.each do |property|
      api_name = puppet_map.has_key?(property) ? puppet_map[property] : property.id2name
      if @property_hash[property] and !@property_hash[property].empty?
	@upload_json[api_name] = @property_hash[property].collect{ |c| {:name => c} }
      else
        @upload_json[api_name] = @default_json[api_name]
      end
    end

    if @property_hash[:servicechecks] and not @property_hash[:servicechecks].empty?
      @upload_json["servicechecks"] = @property_hash[:servicechecks].collect{ |c| { :exception => c["exception"], :event_handler => c["event_handler"], :name => c["name"], :timed_exception => c["timed_exception"] }.delete_if{ |k, v| v.nil? }}
    else
      @upload_json["servicechecks"] = @default_json["servicechecks"]
    end

    if @property_hash[:snmp_interfaces]
      @upload_json["snmpinterfaces"] = @property_hash[:snmp_interfaces].collect{ |c| { :interfacename => c["interface"], :active => c["enabled"], :discards_critical => c["discards_critical"], :discards_warning => c["discards_warning"], :errors_warning => c["errors_warning"], :errors_critical => c["errors_critical"], :throughput_critical => c["throughput_critical"], :throughput_warning => c["throughput_warning"] } }
    else
      @upload_json["snmpinterfaces"] = @default_json["snmpinterfaces"]
    end

    if @property_hash[:variables]
      @upload_json["hostattributes"] = @property_hash[:variables].collect{ |c| {:name => c["name"], :value => c["value"], :arg1 => c["arg1"], :arg2 => c["arg2"], :arg3 => c["arg3"], :arg4 => c["arg4"], :encrypted_arg1 => c["encrypted_arg1"], :encrypted_arg2 => c["encrypted_arg2"], :encrypted_arg3 => c["encrypted_arg3"], :encrypted_arg4 => c["encrypted_arg4"] }.delete_if{|k,v| v.nil?} }
    else
      @upload_json["hostattributes"] = @default_json["hostattributes"]
    end


    Puppet.debug "The json is #{@upload_json}"

    #Send the json to Opsview
    create_or_update_api_object @upload_json.to_json

    #Reload will be deferred until all resources have been processed
    if defined? @resource[:reload_opsview]
      if @resource[:reload_opsview].to_s == "true"
        Puppet.notice "Scheduled to reload Opsview for #{resource[:name]}"
        do_reload_opsview
      else
        Puppet.notice "Configured NOT to reload Opsview for #{resource[:name]}"
      end
    end

    @property_hash.clear
    @upload_json.clear
    @default_json.clear

  end

  #Define the base json to be used when creating new objects in Opsview
  def default_object
   json = '
   {
      "name" : "Puppet-created host",
      "alias" : "",
      "business_components" : [],
      "check_attempts" : "2",
      "check_command" : {
         "name" : "ping"
      },
      "check_interval" : "300",
      "check_period" : {
         "name" : "24x7"
      },
      "enable_snmp" : "0",
      "encrypted_rancid_password" : "",
      "encrypted_snmp_community" : "",
      "encrypted_snmpv3_authpassword" : "",
      "encrypted_snmpv3_privpassword" : "",
      "event_handler" : "",
      "event_handler_always_exec" : "0",
      "flap_detection_enabled" : "1",
      "hostattributes" : [],
      "hostgroup" : {
         "name" : "Monitoring Servers"
      },
      "hosttemplates" : [],
      "icon" : {
         "name" : "LOGO - Opsview",
         "path" : "/images/logos/opsview_small.png"
      },
      "ip" : "localhost",
      "keywords" : [],
      "monitored_by" : {
         "name" : "Master Monitoring Server"
      },
      "notification_interval" : "3600",
      "notification_options" : "u,d,r",
      "notification_period" : {
         "name" : "24x7",
         "ref" : "/rest/config/timeperiod/1"
      },
      "other_addresses" : "",
      "parents" : [],
      "rancid_autoenable" : "0",
      "rancid_connection_type" : "ssh",
      "rancid_username" : "",
      "rancid_vendor" : null,
      "retry_check_interval" : "60",
      "servicechecks" : [],
      "snmp_extended_throughput_data" : "0",
      "snmp_max_msg_size" : "0",
      "snmp_port" : "161",
      "snmp_use_getnext" : "0",
      "snmp_use_ifname" : "0",
      "snmp_version" : "2c",
      "snmpv3_authprotocol" : null,
      "snmpv3_privprotocol" : null,
      "snmpv3_username" : "",
      "tidy_ifdescr_level" : "0",
      "use_rancid" : "0"
   }'
   JSON.parse(json.to_s)
  end

end

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

Puppet::Type.type(:opsview_servicecheck).provide :opsview, :parent => Puppet::Provider::Opsview do
  @object_type='servicecheck'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end

  def internal=(should)
  end

  def self.object_map(object)
    p = { :name      => object["name"],
          :servicecheck => object["name"],
          :checktype => object["checktype"]["name"],
          :full_json => object,
          :ensure    => :present }

      p[:arguments] = object["args"] if defined?object["args"]
      p[:cascaded_from] = object["cascaded_from"]["name"] if defined?object["cascaded_from"]["name"]
      p[:plugin] = object["plugin"]["name"] if defined?object["plugin"]["name"]

    #Loop through fields that do not require any special handling
    [:alert_from_failure, :check_freshness, :check_interval, :description, :event_handler,
    :markdown_filter, :notification_options, :retry_check_interval, :sensitive_arguments].each do |property|
      p[property] = object[property.id2name] if object[property.id2name]
    end

    #Loop through fields that have a name contained inside of a hash that do not require any special handling
    [:check_period, :notification_period, :servicegroup].each do |property|
      p[property] = object[property.id2name]["name"] if defined?object[property.id2name]["name"]
    end

    p[:alert_every_failure] = object["volatile"] if defined?object["volatile"]
    p[:dependencies] = object["dependencies"].collect{ |c| c["name"]} if defined?object["dependencies"]
    p[:event_handler_always_execute] = object["event_handler_always_exec"] if defined?object["event_handler_always_exec"]
    p[:flap_detection] = object["flap_detection_enabled"] if defined?object["flap_detection_enabled"]
    p[:freshness_action] = object["freshness_type"] if defined?object["freshness_type"]
    p[:freshness_status] = object["stale_state"] if defined?object["stale_state"]
    p[:freshness_text] = object["stale_text"] if defined?object["stale_text"]
    p[:freshness_timeout] = object["stale_threshold_seconds"] if defined?object["stale_threshold_seconds"]
    p[:hashtags] = object["keywords"].collect{ |c| c["name"]} if defined?object["keywords"]
    p[:hosttemplates] = object["hosttemplates"].collect{ |c| c["name"]} if defined?object["hosttemplates"]
    p[:invert_plugin_results] = object["invertresults"] if defined?object["invertresults"]
    p[:maximum_check_attempts] = object["check_attempts"] if defined?object["check_attempts"]
    p[:record_output_changes] = object["stalking"] if defined?object["stalking"]
    p[:renotification_interval] = object["notification_interval"] if defined?object["notification_interval"]
    p[:snmp_critical_comparison] = object["critical_comparison"] if defined?object["critical_comparison"]
    p[:snmp_critical_value] = object["critical_value"] if defined?object["critical_value"]
    p[:snmp_warning_comparison] = object["warning_comparison"] if defined?object["warning_comparison"]
    p[:snmp_warning_value] = object["warning_value"] if defined?object["warning_value"]
    p[:snmp_label] = object["label"] if defined?object["label"]
    p[:snmp_oid] = object["oid"] if defined?object["oid"]
    p[:variable] = object["attribute"]["name"] if defined?object["attribute"]["name"]

    if defined?object["snmptraprules"] and object["snmptraprules"].is_a?(Array)
      action_map={ "1" => "Send Alert", "0" => "Stop Processing"}
      alert_level_map={ "0" => "OK", "1" => "WARNING", "2" => "CRITICAL", "3" => "UNKNOWN"}
      p[:snmp_trap_rules] = object["snmptraprules"].collect{ |c| 
       if defined?c["process"] and not c["process"].nil? and c["process"] == "1"
           {"name" => c["name"], "rule" => c["code"], "action" => action_map[c["process"]], "alert_level" => alert_level_map[c["alertlevel"]], "message" => c["message"] }.delete_if{ |k, v| v.nil?}  
       else
           {"name" => c["name"], "rule" => c["code"], "action" => action_map[c["process"]]}.delete_if{ |k, v| v.nil?}  
       end
       }
    end


    p
  end

  def self.instances
    providers = []

    objects = query_api('config/servicecheck',0,'id,name,checktype,plugin,args,attribute,servicegroup,description,check_interval,retry_check_interval,dependencies,check_period,check_attempts,notification_period,notification_interval,sensitive_arguments,flap_detection_enabled,invertresults,markdown_filter,notification_options,stalking,event_handler_always_exec,event_handler,volatile,keywords,check_freshness,freshness_type,stale_state,stale_text,stale_threshold_seconds,cascaded_from,alert_from_failure,oid,label,warning_comparison,critical_comparison,critical_value,warning_value,snmptraprules,hosttemplates')
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
      @upload_json = default_object(@property_hash[:checktype])
    end
    @default_json = default_object(@property_hash[:checktype])

    @upload_json["name"] = @resource[:name]

    #Loop through fields that do not need any kind of special processing
    [:arguments, :alert_from_failure, :check_freshness, :check_interval, :description, :markdown_filter, :notification_options, :retry_check_interval,
     :sensitive_arguments].each do |property|
      if not @property_hash[property].to_s.empty?
        @upload_json[property.id2name] = @property_hash[property]
      end
    end

    #Loop through fields that can take blank values
    [:description, :event_handler, :notification_options].each do |property|
      if @property_hash[property] and not @property_hash[property].nil?
        @upload_json[property.id2name] = @property_hash[property]
      else
        @upload_json[property.id2name] = @default_json[property.id2name]
      end
    end

    #Loop through fields that have a name contained inside of a hash that do not require any special handling
    [:cascaded_from, :check_period, :checktype, :notification_period, :plugin, :servicegroup].each do |property|
      if not @property_hash[property].to_s.empty?
        @upload_json[property.id2name] = { 'name' => @property_hash[property] }
      else
        @upload_json[property.id2name] = @default_json[property.id2name]
      end
    end

    if @property_hash[:arguments]
      @upload_json["args"] = @property_hash[:arguments]
    else
      @upload_json["args"] = @default_json["args"]
    end

    if not @property_hash[:alert_every_failure].to_s.empty?
      @upload_json["volatile"] = @property_hash[:alert_every_failure]
    end

    if @property_hash[:dependencies] and !@property_hash[:dependencies].empty?
      @upload_json["dependencies"] = []
      @property_hash[:dependencies].each do |c|
        @upload_json["dependencies"] << {:name => c}
      end
    else
      @upload_json["dependencies"] = @default_json["dependencies"]
    end

    if @property_hash[:event_handler_always_execute]
      @upload_json["event_handler_always_exec"] = @property_hash[:event_handler_always_execute]
    end

    if not @property_hash[:flap_detection].to_s.empty?
      @upload_json["flap_detection_enabled"] = @property_hash[:flap_detection]
    end

    if not @property_hash[:freshness_action].to_s.empty?
      @upload_json["freshness_type"] = @property_hash[:freshness_action]
    end

    if not @property_hash[:freshness_status].to_s.empty?
      @upload_json["stale_state"] = @property_hash[:freshness_status]
    end

    if @property_hash[:freshness_text] and not @property_hash[:freshness_text].nil?
      @upload_json["stale_text"] = @property_hash[:freshness_text]
    else
      @upload_json["stale_text"] = @default_json["stale_text"]
    end

    if not @property_hash[:freshness_timeout].to_s.empty?
      @upload_json["stale_threshold_seconds"] = @property_hash[:freshness_timeout]
    end

    if @property_hash[:hashtags] and !@property_hash[:hashtags].empty?
      @upload_json["keywords"] = []
      @property_hash[:hashtags].each do |c|
        @upload_json["keywords"] << {:name => c}
      end
    else
      @upload_json["keywords"] = @default_json["keywords"]
    end

    if @property_hash[:hosttemplates] and not @property_hash[:hosttemplates].nil?
      @upload_json["hosttemplates"] = @property_hash[:hosttemplates].collect{ |c| { :name => c} }
    else
      @upload_json["hosttemplates"] = @default_json["hosttemplates"]
    end

    if not @property_hash[:invert_plugin_results].to_s.empty?
      @upload_json["invertresults"] = @property_hash[:invert_plugin_results]
    end

    if not @property_hash[:renotification_interval].to_s.empty?
      @upload_json["notification_interval"] = @property_hash[:renotification_interval]
    else
      @upload_json["notification_interval"] = @default_json["notification_interval"]
    end

    if @property_hash[:record_output_changes]
      @upload_json["stalking"] = @property_hash[:record_output_changes]
    end

    if @property_hash[:snmp_critical_comparison] and not @property_hash[:snmp_critical_comparison].to_s.empty?
      @upload_json["critical_comparison"] = @property_hash[:snmp_critical_comparison]
    else
      @upload_json["critical_comparison"] = @default_json["critical_comparison"]
    end

    if @property_hash[:snmp_critical_value] and not @property_hash[:snmp_critical_value].nil?
      @upload_json["critical_value"] = @property_hash[:snmp_critical_value]
    else
      @upload_json["critical_value"] = @default_json["critical_value"]
    end

    if @property_hash[:snmp_label] and not @property_hash[:snmp_label].nil?
      @upload_json["label"] = @property_hash[:snmp_label]
    else
      @upload_json["label"] = @default_json["label"]
    end

    if @property_hash[:snmp_oid] and not @property_hash[:snmp_oid].nil?
      @upload_json["oid"] = @property_hash[:snmp_oid]
    else
      @upload_json["oid"] = @default_json["oid"]
    end

    if @property_hash[:snmp_trap_rules] and @property_hash[:snmp_trap_rules].is_a?(Array)
      action_map={ "Send Alert" => "1", "Stop Processing" => "0"}
      alert_level_map={ "OK" => "0", "WARNING" => "1", "CRITICAL" => "2", "UNKNOWN" => "3"}
      @upload_json["snmptraprules"] = @property_hash[:snmp_trap_rules].collect{ |c| 
      if c.has_key?("action") and c["action"] == "Send Alert"
        {:name => c["name"], :code => c["rule"], :process => action_map[c["action"]], :alertlevel => alert_level_map[c["alert_level"]], :message => c["message"]} 
      else
        {:name => c["name"], :code => c["rule"], :process => action_map[c["action"]], :alertlevel => 0, :message => c["message"]} 
      end
      }
    end

    if @property_hash[:snmp_warning_comparison] and not @property_hash[:snmp_warning_comparison].to_s.empty?
      @upload_json["warning_comparison"] = @property_hash[:snmp_warning_comparison]
    else
      @upload_json["warning_comparison"] = @default_json["warning_comparison"]
    end

    if @property_hash[:snmp_warning_value] and not @property_hash[:snmp_warning_value].nil?
      @upload_json["warning_value"] = @property_hash[:snmp_warning_value]
    else
      @upload_json["warning_value"] = @default_json["warning_value"]
    end

    if not @property_hash[:variable].to_s.empty?
      @upload_json["attribute"] = { 'name' => @property_hash[:variable] }
    else
      @upload_json["attribute"] = nil
    end


    Puppet.debug "The json is: #{@upload_json.inspect}"
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
  def default_object(type="Active Plugin")
   json_active = '
   {
         "alert_from_failure" : "1",
         "args" : "-H $HOSTADDRESS$",
         "attribute" : null,
         "calculate_rate" : "no",
         "cascaded_from" : null,
         "check_attempts" : "3",
         "check_freshness" : "0",
         "check_interval" : "300",
         "check_period" : null,
         "checktype" : {
            "name" : "Active Plugin"
         },
         "critical_comparison" : null,
         "critical_value" : null,
         "dependencies" : [],
         "description" : "Managed by Puppet",
         "event_handler" : "",
         "event_handler_always_exec" : "0",
         "flap_detection_enabled" : "1",
         "freshness_type" : "renotify",
         "invertresults" : "0",
         "keywords" : [],
         "label" : null,
         "markdown_filter" : "0",
         "name" : "Puppet-created active service check",
         "notification_interval" : null,
         "notification_options" : "w,c,r",
         "notification_period" : null,
         "oid" : null,
         "plugin" : {
            "name" : "check_nrpe"
         },
         "retry_check_interval" : "60",
         "sensitive_arguments" : "1",
         "servicegroup" : {
            "name" : "Application - Alfresco"
         },
         "snmptraprules" : [],
         "stale_state" : "0",
         "stale_text" : "",
         "stale_threshold_seconds" : "3600",
         "stalking" : null,
         "volatile" : "0",
         "warning_comparison" : null,
         "warning_value" : null
   }'
   json_passive = '
   {
         "alert_from_failure" : "1",
         "args" : "",
         "attribute" : null,
         "calculate_rate" : "",
         "cascaded_from" : null,
         "check_attempts" : "0",
         "check_freshness" : "0",
         "check_interval" : null,
         "check_period" : {
            "name" : "24x7"
         },
         "checktype" : {
            "name" : "Passive"
         },
         "critical_comparison" : null,
         "critical_value" : null,
         "dependencies" : [],
         "description" : "Managed by Puppet",
         "event_handler" : "",
         "event_handler_always_exec" : "0",
         "flap_detection_enabled" : "1",
         "freshness_type" : "renotify",
         "hosts" : [],
         "invertresults" : "0",
         "keywords" : [],
         "label" : null,
         "markdown_filter" : "0",
         "name" : "Puppet-created passive service check",
         "notification_interval" : null,
         "notification_options" : "w,c,r,u,f",
         "notification_period" : null,
         "oid" : null,
         "plugin" : null,
         "retry_check_interval" : null,
         "sensitive_arguments" : "1",
         "servicegroup" : {
            "name" : "Application - Alfresco"
         },
         "snmptraprules" : [],
         "stale_state" : "0",
         "stale_text" : "",
         "stale_threshold_seconds" : "3600",
         "stalking" : null,
         "volatile" : "0",
         "warning_comparison" : null,
         "warning_value" : null
   }'
   json_snmp_polling = '
   {
         "alert_from_failure" : "1",
         "args" : "",
         "attribute" : null,
         "calculate_rate" : "no",
         "cascaded_from" : null,
         "check_attempts" : "3",
         "check_freshness" : "0",
         "check_interval" : "300",
         "check_period" : null,
         "checktype" : {
            "name" : "SNMP Polling"
         },
         "critical_comparison" : "string",
         "critical_value" : "",
         "dependencies" : [],
         "description" : "",
         "event_handler" : "",
         "event_handler_always_exec" : "0",
         "flap_detection_enabled" : "1",
         "freshness_type" : "renotify",
         "hosts" : [],
         "hosttemplates" : [],
         "invertresults" : null,
         "keywords" : [],
         "label" : "",
         "markdown_filter" : "0",
         "name" : "Puppet-created SNMP polling service check",
         "notification_interval" : null,
         "notification_options" : "w,c,r,u,f",
         "notification_period" : null,
         "oid" : ".1.3.6.1.2.1.1.1.0",
         "plugin" : null,
         "retry_check_interval" : "60",
         "sensitive_arguments" : "1",
         "servicegroup" : {
            "name" : "Application - Alfresco"
         },
         "snmptraprules" : [],
         "stale_state" : "0",
         "stale_text" : "",
         "stale_threshold_seconds" : "3600",
         "stalking" : "",
         "volatile" : "0",
         "warning_comparison" : "numeric",
         "warning_value" : ""

   }'
   json_snmp_trap = '
   {
         "alert_from_failure" : "1",
         "args" : "",
         "attribute" : null,
         "calculate_rate" : null,
         "cascaded_from" : null,
         "check_attempts" : "0",
         "check_freshness" : "0",
         "check_interval" : null,
         "check_period" : {
            "name" : "24x7"
         },
         "checktype" : {
            "name" : "SNMP trap"
         },
         "critical_comparison" : null,
         "critical_value" : null,
         "dependencies" : [],
         "description" : "",
         "event_handler" : "",
         "event_handler_always_exec" : "0",
         "flap_detection_enabled" : "1",
         "freshness_type" : "renotify",
         "hosts" : [],
         "hosttemplates" : [],
         "invertresults" : null,
         "keywords" : [],
         "label" : null,
         "markdown_filter" : "0",
         "name" : "Puppet-created SNMP trap service check",
         "notification_interval" : null,
         "notification_options" : "w,c,r,u,f",
         "notification_period" : null,
         "oid" : null,
         "plugin" : null,
         "retry_check_interval" : null,
         "sensitive_arguments" : "1",
         "servicegroup" : {
            "name" : "Application - Alfresco"
         },
         "snmptraprules" : [],
         "stale_state" : "0",
         "stale_text" : "",
         "stale_threshold_seconds" : "3600",
         "stalking" : "",
         "volatile" : "0",
         "warning_comparison" : null,
         "warning_value" : null
   }'

   case type.to_s
   when "Active Plugin"
     JSON.parse(json_active.to_s)
   when "Passive"
     JSON.parse(json_passive.to_s)
   when "SNMP Polling"
     JSON.parse(json_snmp_polling.to_s)
   when "SNMP trap"
     JSON.parse(json_snmp_trap.to_s)
   else
     JSON.parse(json_active.to_s)
   end
  end

end

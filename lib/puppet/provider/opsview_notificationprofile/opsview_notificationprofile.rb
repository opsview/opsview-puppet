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

Puppet::Type.type(:opsview_notificationprofile).provide :opsview, :parent => Puppet::Provider::Opsview do
  @object_type='contact'

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
    [:all_business_components, :all_business_services, :all_hostgroups, :all_hashtags, :all_servicegroups,
     :business_component_availability_below, :business_component_notification_options, :business_component_renotification_interval,
     :business_service_availability_below, :business_service_notification_options, :business_service_renotification_interval,
     :include_component_notes, :include_service_notes, :send_from_alert, :stop_after_alert
    ]
  end

  def self.generic_blankable_fields
    [:host_notification_options, :service_notification_options]
  end

  def self.generic_name_fields
    [:notification_period]
  end

  def self.generic_array_name_fields
    [:business_services, :hostgroups, :notification_methods, :servicegroups, :hashtags]
  end
  ######End Define your fields here######

  #SYNTAX for map
  #:puppet_name => "rest_api_name"
  def self.puppet_map
  {
    :all_hashtags => "all_keywords",
    :business_component_notification_options => "business_component_options",
    :business_service_notification_options => "business_service_options",
    :hashtags => "keywords",
    :notification_methods => "notificationmethods",
    :send_from_alert => "notification_level",
    :stop_after_alert => "notification_level_stop"
  } 
  end

  def self.object_map(contact,object)
    p = { :contact => contact,
          :name      => contact+"|"+object["name"],
	  :profile_name => object["name"],
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

    p
  end

  def self.instances
    providers = []

    objects = query_api('config/contact',0,'name,notificationprofiles')
    objects.each do |object|
      if defined?object["notificationprofiles"]
        object["notificationprofiles"].each do |profile|
          providers << new(object_map(object["name"],profile))
	end
      end
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

    @upload_json["name"] = @property_hash[:profile_name]
    @upload_json.delete("ref")

    contact_filter=sprintf('{"name":{"=":"%s"}}',@resource[:name].split("|").first)
    Puppet.debug "FILTER: #{contact_filter}"
    contact_json=self.class.query_api('config/contact',0,'name,notificationprofiles',contact_filter).first

    if contact_json.nil?
      Puppet.warning "Contact [#{@resource[:name].split("|").first}] does not exist ... skipping"
      return
    end

    if contact_json["notificationprofiles"].empty?
      Puppet.debug "No existing profiles found for #{contact_json["name"]}"
      contact_json["notificationprofiles"] = [@upload_json]
    else
      #Determine if our profile already exists in the array
      profile_exists=0
      contact_json["notificationprofiles"].each_with_index do |profile,index|
        Puppet.debug "Searching profile: #{profile}"
	if profile["name"] == @upload_json["name"]
	  Puppet.debug "Found profile match at index [#{index}]" 
	  contact_json["notificationprofiles"][index] = @upload_json
	  profile_exists=1
	  break
	end
      end
      contact_json["notificationprofiles"] << @upload_json if profile_exists == 0
    end

    Puppet.debug "The json for the profile is #{@upload_json}"
    Puppet.debug "The json to upload is: #{contact_json}"

    #Send the json to Opsview
    create_or_update_api_object contact_json.to_json

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
         "name" : "Puppet-created notificationprofile",
         "all_business_components" : "0",
         "all_business_services" : "0",
         "all_hostgroups" : "1",
         "all_keywords" : "0",
         "all_servicegroups" : "1",
         "business_component_availability_below" : "99.999",
         "business_component_options" : "f,i",
         "business_component_renotification_interval" : "1800",
         "business_components" : [],
         "business_service_availability_below" : "99.999",
         "business_service_options" : "o,i",
         "business_service_renotification_interval" : "1800",
         "business_services" : [],
         "host_notification_options" : "d,u,r,f",
         "hostgroups" : [],
         "include_component_notes" : "0",
         "include_service_notes" : "0",
         "keywords" : [],
         "notification_level" : "1",
         "notification_level_stop" : "0",
         "notification_period" : {
            "name" : "24x7"
         },
         "notificationmethods" : [],
         "service_notification_options" : "w,r,u,c,f",
         "servicegroups" : []
   }'
   JSON.parse(json.to_s)
  end

end

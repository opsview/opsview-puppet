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

Puppet::Type.type(:opsview_hosttemplate).provide :opsview, :parent => Puppet::Provider::Opsview do
  @object_type='hosttemplate'

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
    []
  end

  def self.generic_blankable_fields
    [:description]
  end

  def self.generic_name_fields
    []
  end

  def self.generic_array_name_fields
    [:hosts]
  end
  ######End Define your fields here######

  #SYNTAX for map
  #:puppet_name => "rest_api_name"
  def self.puppet_map
  {
  } 
  end

  def self.object_map(object)
    p = { :name      => object["name"],
          :hosttemplate => object["name"],
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
    p[:management_urls] = object["managementurls"].collect{ |c| {"name" => c["name"], "url" => c["url"]}.delete_if{ |k, v| v.nil?}  } if defined?object["managementurls"]


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

    if @property_hash[:management_urls] and not @property_hash[:management_urls].empty?
      @upload_json["managementurls"] = @property_hash[:management_urls].collect{ |c| { :name => c["name"], :url => c["url"] }.delete_if{ |k, v| v.nil? }}
    else
      @upload_json["managementurls"] = @default_json["managementurls"]
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
         "name" : "Puppet-created hosttemplate",
         "description" : "",
         "has_icon" : "0",
         "hosts" : [],
         "managementurls" : [],
         "servicechecks" : []
   }'
   JSON.parse(json.to_s)
  end

end

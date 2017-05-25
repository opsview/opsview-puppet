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

Puppet::Type.newtype(:opsview_host) do
  desc "Puppet type for Opsview host"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the host"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9._-]+)*$/)
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:host) do
    desc "Name of the host"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9._-]+)*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic properties##################
  [:check_attempts, :check_command, :check_period, :hostgroup, :icon, :ip, :monitored_by, :name, :notification_period, 
   :rancid_connection_type, :rancid_password, :rancid_vendor, :snmp_community, :snmp_message_size, :snmp_port, :snmp_ifdescr_level, :snmp_version,
   :snmpv3_authentication_protocol, :snmpv3_privacy_protocol].each do |property|
    newproperty(property) do
      desc "Generic property"
      case property
        when :rancid_connection_type
	  newvalues(:ssh, :telnet)
        when :rancid_vendor
	  newvalues(:AGM, :Alteon, :Baynet, :Cat5, :Cisco, :Ellacoya, :Enterasys, :ERX, :Extreme, :EZT3, :Force10, :Foundry, :Hitachi, :HP, :Juniper, :MRTD, :Netscaler, :Netscreen, :Procket, :Redback, :Riverstone, :SMC, :TNT, :Zebra)
	when :snmp_message_size
	  newvalues(:default, :"1Kio", :"2Kio", :"4Kio", :"8Kio", :"16Kio", :"32Kio", :"64Kio")
	  munge do |value|
	    case value.to_s
	      when /^(\d+)Kio$/
	        ($1.to_i*1024-1)
	      else
	        0
	    end
	  end
	when :snmp_version
	  newvalues(:"1", :"2c", :"3")
    	when :snmpv3_authentication_protocol
	  newvalues(:"md5", :"sha")
    	when :snmpv3_privacy_protocol
	  newvalues(:"des", :"aes", :"aes128")
    	when :snmp_ifdescr_level
	  newvalues(:off, 0, 1, 2, 3, 4, 5, 6)
	  munge do |value|
	    case value.to_s
	      when "off"
	        0
	      else
	        value
	    end
	  end
  end
    end
  end
  ##################End Generic properties##################

  ##################Begin Generic nullable properties##################
  [:description, :event_handler, :other_addresses, :rancid_username, :snmpv3_authentication_password, :snmpv3_privacy_password, :snmpv3_username].each do |property|
    newproperty(property) do
      desc "Generic nullable property"
      case property
        when :other_addresses
	  validate do |value|
	    unless value=~/^([\w\.])+(,[\w\.]+)*$/
              raise ArgumentError, "%s is not a valid format - must be a comma-separated list of addresses - ip1,ip2,ip3,..,ipN" % value
	    end
	  end
      end
      def insync?(is)
        if is == :absent and @should.first.empty?
	  true
	else
	  is == @should.first
	end
      end
    end
  end
  ##################End Generic nullable properties##################

  ##################Begin time-based properties##################
  [:check_interval, :renotification_interval, :retry_check_interval].each do |property|
    newproperty(property) do
      desc "Interval property"
      validate do |value|
        unless value =~ /^\d+[dmwhs]{0,1}(\s\d+[dmwhs]{0,1})*$/
          raise ArgumentError, "%s is not a valid timeout - valid examples are 5, 10s, 20m, 1h, 2d, 18h 20m" % value
        end
      end
      munge do |value|
        multiplier={ 'd' => 86400, 'h' => 3600, 'm' => 60, 'w' => 604800, 's' => 1 }
        total_time=0
        value.split(" ").each do |time|
          case time
            when /([dmwhs]$)/
              time.chop!
              total_time += multiplier[$1] * time.to_i
            else
              total_time += time.to_i
          end
        end
        total_time
      end
    end
  end
  ##################End time-based properties##################

  ##################Begin true/false properties##################
  [:enable_rancid, :enable_snmp, :event_handler_always_execute, :snmp_extended_throughput_data, :flap_detection, :rancid_autoenable, :snmp_use_getnext, :snmp_use_ifname].each do |property|
    newproperty(property) do
      desc "Generic true/false property"
      newvalues(:"0", :"1", :true, :false)
      munge do |value|
        case value
        when true
          :"1"
        when false
          :"0"
        else
          value
        end
      end
    end
  end
  ##################End true/false properties##################

  ##################Begin array properties##################
  [:hashtags, :hosttemplates, :parents].each do |property|
    newproperty(property, :array_matching => :all) do
      desc "Array of property"
      def insync?(is)
        #Top block is for updating existing objects, bottom block is for new ones (is = :absent)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.uniq.sort == @should.uniq.sort
        else
          is == @should
        end
      end
    end
  end
  ##################End array properties##################

  ##################Start Hash array properties##################
  [:servicechecks, :variables].each do |property|
    newproperty(property, :array_matching => :all) do
      desc "Array property that has hashes with multiple entries - order does not matter"
      munge do |value|
       if value.is_a?(String)
         { "name" => value }
       else
         value
       end
      end
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is - @should == @should - is
        else
          is == @should
        end
      end
    end
  end
  ##################End Hash array properties##################

  ##################Begin notification properties##################
  [:notification_options].each do |property|
    newproperty(property) do
      desc "Notification options for the service check"
      case property
        when :notification_options
          validate do |value|
            unless value =~ /^$|^[durf]+(,[durf])*$/
              raise ArgumentError, "%s is not valid for host notifications. The value should be a comma-separated string containing the letters d, u, r, or f" % value
            end
          end
      end
      munge do |value|
        value.split(",").uniq.sort.join(",")
      end
      def insync?(is)
        if is == :absent and @should.first.empty?
          true
        elsif is == :absent and not @should.first.empty?
          false
        else
          is.split(",").uniq.sort.join(",") == @should.first
        end
      end
    end
  end
  ##################End notification properties##################

  #################Special handling for snmp interfaces
  newproperty(:snmp_interfaces, :array_matching => :all) do
    desc "SNMP interfaces"
    munge do |value|
      value.each do |k,v|
        if v.eql?("-")
	  value[k] = nil
	end
      end
      value  
    end
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is - @should == @should - is
      else
        is == @should
      end
    end
  end
  #################/Special handling for snmp interfaces

  autorequire(:opsview_hashtag) do
    self[:hashtags].collect{ |c| c["name"] if c["name"] } if defined?self[:hashtags] and not self[:hashtags].nil?
  end

  autorequire(:opsview_host) do
    self[:parents] if defined?self[:parents]
  end

  autorequire(:opsview_hostcheckcommand) do
    self[:check_command] if defined?self[:check_command]
  end

  autorequire(:opsview_hostgroup) do
    self[:hostgroup] if defined?self[:hostgroup]
  end

  autorequire(:opsview_hosttemplate) do
    self[:hosttemplates].collect{ |c| c["name"] if c["name"] } if defined?self[:hosttemplates] and not self[:hosttemplates].nil?
  end

  autorequire(:opsview_servicecheck) do
    self[:servicechecks].collect{ |c| c["name"] if c["name"] } if defined?self[:servicechecks] and not self[:servicechecks].nil?
  end

  autorequire(:opsview_timeperiod) do
    self[:check_period] if defined?self[:check_period]
  end

  autorequire(:opsview_timeperiod) do
    self[:notification_period] if defined?self[:notification_period]
  end

  autorequire(:opsview_timeperiod) do
    self[:servicechecks].collect{ |c| c["timed_exception"]["timeperiod"]["name"] if (c["timed_exception"] and c['timed_exception']['timeperiod']['name']) } if defined?self[:servicechecks] and not self[:servicechecks].nil?
  end

  autorequire(:opsview_variable) do
    self[:variables].collect{ |c| c["name"] if c["name"] } if defined?self[:variables] and not self[:variables].nil?
  end

  #TODO require monitoring server in self[:monitored_by]


end

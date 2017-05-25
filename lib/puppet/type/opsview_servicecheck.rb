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

Puppet::Type.newtype(:opsview_servicecheck) do
  desc "Puppet type for Opsview service checks"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the service check"
    newvalues(/^[a-zA-Z0-9_-]+(\s*[\.\/a-zA-Z0-9_-]+)*$/)
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:servicecheck) do
    desc "Name of the service check"
    defaultto {@resource[:name]}
  end
  
  newproperty(:checktype) do
    desc "The type of service check"
    newvalues(:"Active Plugin",:"SNMP trap",:"Passive",:"SNMP Polling")
    defaultto :"Active Plugin"
  end

  ##################Begin Generic properties##################
  [:alert_from_failure, :arguments, :description, :freshness_text,
   :event_handler, :plugin, :servicegroup, :snmp_critical_value, :snmp_warning_value, :variable].each do |property|
    newproperty(property) do
      desc "Generic service check property"
    end
  end
  ##################End Generic properties##################

  ##################Begin Generic nullable properties##################
  [:cascaded_from, :check_period, :notification_period].each do |property|
    newproperty(property) do
      desc "Generic nullable service check property"
      def insync?(is)
        if is == :absent and @should.first.empty?
	  true
	else
	  is == @should
	end
      end
    end
  end
  ##################End Generic nullable properties##################

  ##################Begin time-based properties##################
  [:check_interval, :retry_check_interval, :freshness_timeout].each do |property|
    newproperty(property) do
      desc "Interval property for the service check"
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

  newproperty(:renotification_interval) do
    desc "The re-notification interval for a service check"
    validate do |value|
      unless value =~ /^\d+[dmwhs]{0,1}(\s\d+[dmwhs]{0,1})*$|^$/
        raise ArgumentError, "%s is not a valid timeout - valid examples are 5, 10s, 20m, 1h, 2d, 18h 20m, or blank" % value
      end
    end
    munge do |value|
      return value if value.to_s.empty?
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
    def insync?(is)
      if is != :absent
        return is.to_i == @should.first.to_i
      else
        if is == :absent and @should.first.to_s.empty?
          return true
	end
      end
      return false
    end
  end
  ##################End time-based properties##################

  ##################Begin true/false properties##################
  [:check_freshness, :event_handler_always_execute, :flap_detection, :invert_plugin_results,
   :markdown_filter, :sensitive_arguments].each do |property|
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


  ##################Begin notification properties##################
  [:notification_options, :record_output_changes].each do |property|
    newproperty(property) do
      desc "Notification options for the service check"
      case property
        when :notification_options
          validate do |value|
            unless value =~ /^$|^[wcruf]+(,[wcruf])*$/
              raise ArgumentError, "%s is not valid for notifications. The value should be a comma-separated string containing the letters w,c,r,u, and f" % value
            end
          end
        when :record_output_changes
	  validate do |value|
	    unless value =~ /^$|^[wcuo]+(,[wcuo])*$/
	      raise ArgumentError, "%s is not valid for notifications. The value should be a comma-separated string containing the letters w,c,u, and o" % value
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

  newproperty(:alert_every_failure) do
    desc "Raises a notification on every failure, not just the first one"
    newvalues(:"0", :"1", :"2", :enable, :disable, :"enable with re-notification interval")
    munge do |value|
      case value.to_sym
      when :enable
       :"1"
      when :disable
       :"0"
      when :"enable with re-notification interval"
       :"2"
      else
       value
      end
    end
  end
  ##################End notification properties##################

  
  ##################Start freshness properties##################
  newproperty(:freshness_action) do
    desc "Action to take when freshness timeout has been reached"
    newvalues(:set_stale,:renotify, /^[Rr]esend [Nn]otifications$/, /^[Ss]ubmit [Rr]esult$/)
    munge do |value|
      case value.to_s.downcase
      when "resend notifications"
       :renotify
      when "submit result"
       :set_stale
      else
       value
      end
    end
  end

  newproperty(:freshness_status) do
    desc "Action to take when freshness timeout has been reached"
    newvalues(:WARNING,:CRITICAL,:OK,:UNKNOWN,:"0", :"1", :"2", :"3")
    munge do |value|
      case value.to_sym
      when :OK
       :"0"
      when :WARNING
       :"1"
      when :CRITICAL
       :"2"
      when :UNKNOWN
       :"3"
      else
       value
      end
    end
  end
  ##################End freshness properties##################

  newproperty(:maximum_check_attempts) do
    desc "Maximum number of check attempts"
    newvalues(/\d+/)
  end

  ##################Begin array properties##################
  [:dependencies, :hashtags, :hosttemplates].each do |property|
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

  newproperty(:snmp_label) do
    desc "SNMP label for service check"
    newvalues(/^[\w]{0,40}$/)
  end

  newproperty(:snmp_oid) do
    desc "SNMP OID for service check"
    newvalues(/^(\d|\.\d)+(\.d)*$/)
  end

  newproperty(:snmp_critical_comparison) do
    desc "SNMP polling Critical Comparison"
    newvalues(:numeric, /^[Nn]umeric [Cc]omparison$/, :"==", :"<", :">", :separator, :"---", :string, /^[Ss]tring [Cc]omparison$/, :eq, :equals, :ne, :"not equals", :regex)
    munge do |value|
      case value.to_s.downcase
        when "numeric comparison"
	  :numeric
        when "---"
	  :separator
	when "string comparison"
	  :string
	when "equals"
	  :eq
	when "not equals"
	  :ne
	else
	  value
      end
    end
  end

  newproperty(:snmp_trap_rules, :array_matching => :all) do
    desc "Array of SNMP trap hashes for this service check"

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end

    validate do |value|
      unless value.is_a?(Hash)
	      raise ArgumentError, "%s is not a valid set of snmp trap rules. You should have an array of hashes." % value
      end

      if not value.has_key?("action") or (value["action"] == "Send Alert")
         unless value.has_key?("name") and value.has_key?("message") and value.has_key?("alert_level") and value["alert_level"]=~/OK|WARNING|CRITICAL|UNKNOWN/ and value.has_key?("rule")
	   raise ArgumentError, "%s is not a valid snmp trap rule. The format should match: {'name'=>'rule name','action'=>'Send Alert|Stop Processing','alert_level'=>'OK|WARNING|CRITICAL|UNKNOWN','message'=>'text','rule'=>'trap rule'}" % value
	 end
      elsif value["action"] == "Stop Processing"
         unless value.has_key?("name") and value.has_key?("rule")
	   raise ArgumentError, "%s is not a valid snmp trap rule. The format should match: {'name'=>'rule name','action'=>'Stop Processing','rule'=>'trap rule'}" % value
	 end
      end
    end

    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.collect{ |c| c.sort_by{|k,v|k} } == @should.collect{ |c| c.sort_by{|k,v|k} }
      else
        is == @should
      end
    end
  end

  newproperty(:snmp_warning_comparison) do
    desc "SNMP polling Warning Comparison"
    newvalues(:numeric, /^[Nn]umeric [Cc]omparison$/, :"==", :"<", :">")
    munge do |value|
      case value.to_s.downcase
        when "numeric comparison"
	  :numeric
	else
	  value
      end
    end
  end

  autorequire(:opsview_hashtag) do
    self[:hashtags] if defined?self[:hashtags]
  end

  autorequire(:opsview_hosttemplate) do
    self[:hosttemplates] if defined?self[:hosttemplates]
  end

  autorequire(:opsview_servicegroup) do
    self[:servicegroup] if defined?self[:servicegroup]
  end

  autorequire(:opsview_servicecheck) do
    self[:cascaded_from] if defined?self[:cascaded_from]
  end

  autorequire(:opsview_servicecheck) do
    self[:dependencies] if defined?self[:dependencies]
  end

  autorequire(:opsview_timeperiod) do
    self[:check_period] if defined?self[:check_period]
  end

  autorequire(:opsview_timeperiod) do
    self[:notification_period] if defined?self[:notification_period]
  end

  autorequire(:opsview_variable) do
    self[:variable] if defined?self[:variable]
  end

end

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

Puppet::Type.newtype(:opsview_notificationprofile) do
  desc "Puppet type for Opsview notificationprofile"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the notification profile"
    newvalues(/^[\w]+|.*$/)
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:profile_name) do
    desc "Name of the notification profile"
    defaultto {@resource[:name].sub(/.*\|/,'')}
  end

  ##################Begin Generic properties##################
  [:business_component_availability_below, :business_service_availability_below, :contact, :notification_period,
   :send_from_alert, :stop_after_alert].each do |property|
    newproperty(property) do
      desc "Generic property"
    end
  end
  ##################End Generic properties##################
  
  ##################Begin true/false properties##################
  [:all_business_components, :all_business_services, :all_hostgroups, :all_hashtags, :all_servicegroups,
   :include_component_notes, :include_service_notes].each do |property|
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
  [:business_component_notification_options, :business_service_notification_options, :host_notification_options, :service_notification_options].each do |property|
    newproperty(property) do
      desc "Notification options for the service check"
      case property
        when :business_component_notification_options
          validate do |value|
            unless value =~ /^$|^[fiar]+(,[fiar])*$/
              raise ArgumentError, "%s is not valid for business component notifications. The value should be a comma-separated string containing the letters f,i,a, or r" % value
            end
          end
        when :business_service_notification_options
          validate do |value|
            unless value =~ /^$|^[oiar]+(,[oiar])*$/
              raise ArgumentError, "%s is not valid for business service notifications. The value should be a comma-separated string containing the letters o, i, a, or r" % value
            end
          end
        when :host_notification_options
          validate do |value|
            unless value =~ /^$|^[durf]+(,[durf])*$/
              raise ArgumentError, "%s is not valid for host notifications. The value should be a comma-separated string containing the letters d, u, r, or f" % value
            end
          end
        when :service_notification_options
          validate do |value|
            unless value =~ /^$|^[wrucf]+(,[wrucf])*$/
              raise ArgumentError, "%s is not valid for host notifications. The value should be a comma-separated string containing the letters w,r,u,c, or f" % value
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

  ##################Begin array properties##################
  [:business_services, :hostgroups, :notification_methods, :servicegroups, :hashtags].each do |property|
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

  autorequire(:opsview_business_services) do
    self[:business_services] if defined?self[:business_services]
  end

  autorequire(:opsview_contact) do
    self[:name].split("|").first if defined?self[:name] and not self[:name].nil?
  end

  autorequire(:opsview_hashtag) do
    self[:hashtags] if defined?self[:hashtags]
  end

  autorequire(:opsview_hostgroup) do
    self[:hostgroups] if defined?self[:hostgroups]
  end

  autorequire(:opsview_notificationmethod) do
    self[:notification_methods] if defined?self[:notification_methods]
  end

  autorequire(:opsview_servicegroup) do
    self[:servicegroups] if defined?self[:servicegroups]
  end
  
end

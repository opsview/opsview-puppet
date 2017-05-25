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

Puppet::Type.newtype(:opsview_contact) do
  desc "Puppet type for Opsview contact"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the contact"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9_-]+)*$/)
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:full_name) do
    desc "Full Name of the contact"
    defaultto {@resource[:name]}
  end

  ##################Begin Generic properties##################
  [:realm, :role].each do |property|
    newproperty(property) do
      desc "Generic property"
    end
  end
  ##################End Generic properties##################

  ##################Begin Generic nullable properties##################
  [:description, :homepage_id, :language].each do |property|
    newproperty(property) do
      desc "Generic nullable property"
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


  ##################Begin true/false properties##################
  [:tips].each do |property|
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
  [:shared_notification_profiles].each do |property|
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
  
  ##################Start Hash array properties#################
  [:variables].each do |property|
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
 
  autorequire(:opsview_role) do
    self[:role]
  end

  #TODO autorequire shared notification profiles

end

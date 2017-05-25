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

Puppet::Type.newtype(:opsview_hosttemplate) do
  desc "Puppet type for Opsview hosttemplate"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the hosttemplate"
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

  newproperty(:hosttemplate) do
    desc "Name of the hosttemplate"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9_-]+)*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic nullable properties##################
  [:description].each do |property|
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

  ##################Begin array properties##################
  [:hosts].each do |property|
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

  [:management_urls, :servicechecks].each do |property|
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

 autorequire(:opsview_host) do
   self[:hosts] if defined?self[:hosts]
 end

 autorequire(:opsview_servicecheck) do
   self[:servicechecks].collect{ |c| c["name"] if c["name"] } if defined?self[:servicechecks] and not self[:servicechecks].nil?
 end

 autorequire(:opsview_timeperiod) do
   self[:servicechecks].collect{ |c| c["timed_exception"]["timeperiod"]["name"] if (c["timed_exception"] and c['timed_exception']['timeperiod']['name']) } if defined?self[:servicechecks] and not self[:servicechecks].nil?
 end

end

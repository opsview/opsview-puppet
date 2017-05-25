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

Puppet::Type.newtype(:opsview_skeleton) do
  desc "Puppet type for Opsview skeleton"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the skeleton"
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

  newproperty(:skeleton) do
    desc "Name of the skeleton"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9_-]+)*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic properties##################
  [].each do |property|
    newproperty(property) do
      desc "Generic property"
    end
  end
  ##################End Generic properties##################

  ##################Begin Generic nullable properties##################
  [].each do |property|
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

  ##################Begin time-based properties##################
  [].each do |property|
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

  ##################Begin nullable time-based properties##################
  [].each do |property| 
    newproperty(property) do
      desc "Nullable time-based property"
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
  end
  ##################End nullable time-based properties##################

  ##################Begin true/false properties##################
  [].each do |property|
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
  [].each do |property|
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
  [].each do |property|
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


end

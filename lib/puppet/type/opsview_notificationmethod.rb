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

Puppet::Type.newtype(:opsview_notificationmethod) do
  desc "Puppet type for Opsview notificationmethod"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the notification method"
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

  newproperty(:notificationmethod) do
    desc "Name of the notification method"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9_-]+)*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic nullable properties##################
  [:command,:user_variables].each do |property|
    newproperty(property) do
      desc "Generic nullable property"
      case property
      when :command
        validate do |value|
	  unless value =~ /^\w+(\w)*$/
	    raise ArgumentError, "%s is not a valid command" % value
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

  ##################Begin true/false properties##################
  [:active, :run_on_master].each do |property|
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


end

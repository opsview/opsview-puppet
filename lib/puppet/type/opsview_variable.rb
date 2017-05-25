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

Puppet::Type.newtype(:opsview_variable) do
  desc "Puppet type for Opsview variable"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the variable"
    newvalues(/^[_A-Za-z]+$/)
    munge do |value|
      value.upcase
    end
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:variable) do
    desc "Name of the variable"
    newvalues(/^[_A-Z]+$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic nullable properties##################
  [:arg1, :arg2, :arg3, :arg4, :encrypted_arg1, :encrypted_arg2, :encrypted_arg3, :encrypted_arg4, :label1, :label2, :label3, :label4, :value].each do |property|
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
  [:secured1, :secured2, :secured3, :secured4].each do |property|
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

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

Puppet::Type.newtype(:opsview_timeperiod) do
  desc "Puppet type for Opsview timeperiod"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the timeperiod"
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

  newproperty(:timeperiod) do
    desc "Name of the timeperiod"
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
  [:description, :sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday].each do |property|
    newproperty(property) do
      desc "Generic nullable property"
      unless property == :description
        validate do |value|
          unless value =~ /^(\d{2}:\d{2}-\d{2}:\d{2}(,\d{2}:\d{2}-\d{2}:\d{2})*)?$/
            raise ArgumentError, "%s is not a valid time period - format is HH:MM-HH:MM[,HH:MM-HH:MM][...] " % value
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

end

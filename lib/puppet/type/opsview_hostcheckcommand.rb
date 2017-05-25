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

Puppet::Type.newtype(:opsview_hostcheckcommand) do
  desc "Puppet type for Opsview hostcheckcommand"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the host check command"
    newvalues(/^[[:ascii:]]+(\s*[[:ascii:]])*$/)
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:hostcheckcommand) do
    desc "Name of the host check command"
    newvalues(/^[[:ascii:]]+(\s*[[:ascii:]])*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic properties##################
  [:plugin, :priority].each do |property|
    newproperty(property) do
      desc "Generic property"
    end
  end
  ##################End Generic properties##################

  ##################Begin Generic nullable properties##################
  [:arguments].each do |property|
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

end

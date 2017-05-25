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

Puppet::Type.newtype(:opsview_bsmcomponent) do
  desc "Puppet type for Opsview bsmcomponent"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the bsm component"
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

  newproperty(:bsmcomponent) do
    desc "Name of the bsm component"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[a-zA-Z0-9_-]+)*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic properties##################
  [:host_template, :required_online].each do |property|
    newproperty(property) do
      desc "Generic property"
    end
  end
  ##################End Generic properties##################
  
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

  autorequire(:opsview_host) do
    self[:hosts] if defined?self[:hosts]
  end

  autorequire(:opsview_hosttemplate) do
    self[:host_template] if defined?self[:host_template]
  end

end

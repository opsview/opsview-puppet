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

Puppet::Type.newtype(:opsview_role) do
  desc "Puppet type for Opsview role"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the role"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[,\w_-]+)*$/)
  end
  
  newparam(:reload_opsview) do
    desc "Whether to reload Opsview at the end of the Puppet sync"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internally used to manage reloads"
    defaultto :used_to_calculate_reloads_for_puppet_only
  end

  newproperty(:role) do
    desc "Name of the role"
    newvalues(/^[a-zA-Z0-9_-]+(\s?[,\w_-]+)*$/)
    defaultto {@resource[:name]}
  end

  ##################Begin Generic nullable properties##################
  [:tenancy].each do |property|
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
  [:all_bsm_components, :all_bsm_edit, :all_bsm_view, :all_hostgroups, :all_hashtags, :all_monitoringservers, :all_servicegroups].each do |property|
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
  [:configure_hostgroups, :hostgroups, :hashtags, :servicegroups, :access, :monitoring_servers].each do |property|
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
  
  newproperty(:business_services, :array_matching => :all) do
    desc "BSM services for role"

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, "%s is not a valid set of business services. You should have an array of hashes." % value
      end
      unless value.has_key?("edit") and value["edit"].to_s =~ /true|false/ and value.has_key?("name") and value["name"] !~/^$/
        raise ArgumentError, "%s is not a valid business service. Please ensure your configuration matches the following syntax: { 'name' => 'bsm name', 'edit' => 'true|false'}" % value
      end
      value
    end


    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.collect{ |c| c.sort_by{|k,v|k} }.sort == @should.collect{ |c| c.sort_by{|k,v|k} }.sort
      else
        is == @should
      end
    end

  end

  autorequire(:opsview_bsmservice) do
    self[:business_services].collect{ |c| c["name"] } if defined?self[:business_services] and not self[:business_services].nil?
  end

  autorequire(:opsview_hashtag) do
    self[:hashtags] if defined?self[:hashtags]
  end

  autorequire(:opsview_hostgroup) do
    self[:hostgroups] if defined?self[:hostgroups]
  end

  autorequire(:opsview_servicegroup) do
    self[:servicegroups] if defined?self[:servicegroups]
  end

  autorequire(:opsview_tenancy) do
    self[:tenancy] if defined?self[:tenancy]
  end

  ##TODO autorequire monitoringserver

end

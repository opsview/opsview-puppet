Opsview_bsmservice{
  ensure => present,
  reload_opsview => true
}

opsview_bsmservice{'Company Website':
  components => ['example-component1','example-component2']
}

opsview_bsmservice{'Sales':
  components => ['example-component1']
}

Opsview_bsmcomponent{
  ensure => present,
  reload_opsview => true
}

opsview_bsmcomponent{'example-component1':
  hosts => ['example-host','example-networking-host'],
  host_template => 'Network - Base',
  required_online => '2'
}

opsview_bsmcomponent{'example-component2':
  hosts => ['example-host'],
  host_template => 'example-other',
  required_online => '0'
}

Opsview_contact{
  ensure => present,
  realm => 'local',
  reload_opsview => true,
  tips => true
}

opsview_contact{'example-contact':
  full_name => "Example Example",
  description => "Example Puppet User",
  role => 'example-role',
  variables => [
                 {'name' => 'EMAIL', 'value' => 'puppetuser@opsview.com'},
                 {'name' => 'RSS_COLLAPSED', 'value' => '1'},
                 {'name' => 'RSS_MAXIMUM_AGE', 'value' => '1440'},
                 {'name' => 'RSS_MAXIMUM_ITEMS', 'value' => '30'}
               ]
}

Opsview_hashtag{
  ensure => present,
  reload_opsview => true,
  description => "Hashtag created by Puppet",
  exclude_handled => false,
  visible => true,
  show_contextual_menus => true,
  style => group_by_host
}

opsview_hashtag{'example-public-hashtag':
  description => "Example public hashtag",
  public => true
}

opsview_hashtag{'example-hashtag':
  description => "Example hashtag"
}

Opsview_host{
  ensure => present,
  reload_opsview => true,
  icon => 'LOGO - Opsview',
  ip => 'localhost',
  check_command => 'example-checkcommand',
  check_attempts => 2,
  check_period => '24x7',
  notification_period => '24x7',
  check_interval => '5m',
  renotification_interval => '60m',
  retry_check_interval => '10m',
}

opsview_host{'example-parent':}

opsview_host{'example-host':
  other_addresses => '127.0.0.1',
  hostgroup => 'example-linux',
  hosttemplates => ['example-other', 'Network - Base', 'OS - Unix Base'],
  icon => 'LOGO - Linux Penguin',
  parents => ['example-parent','example-networking-host'],
  variables => [ 
                 {"name" => "DISK", "value" => "/" },
                 {"name" => "DISK", "value" => "/tmp", "arg1" => "-w 3% -c 1%"}
               ],
  servicechecks => 'Opsview Application Status'

}

opsview_host{'example-networking-host':
  hostgroup => 'example-networking',
  hosttemplates => ['example-snmppolling','example-snmptraps', 'Network - Base'],
  icon => 'SYMBOL - Network',
  enable_snmp => true,
  snmp_community => 'bdd4dcdb1375a56dff0bbe2d9ce47272b7ecc64d90737bffa5dabf6f0a87080f',
  snmp_port => 161,
  snmp_version => 2c,
  snmp_ifdescr_level => 'off',
  snmp_extended_throughput_data => false,
  snmp_message_size => 'default',
  snmp_interfaces => [ 
                       {"interface" => "", "enabled" => "0", "throughput_warning" => "-", "throughput_critical" => "0:75%", "errors_warning" => "-", "errors_critical" => "10", "discards_warning" => "-", "discards_critical" => "10" },
                       {"interface"=>"Serial0/0", "enabled"=>"1", "throughput_warning"=>"", "throughput_critical" => "", "errors_warning" => "", "errors_critical" => "", "discards_warning" => "", "discards_critical" => "" }
                     ]

}

Opsview_hostcheckcommand{
  ensure => present,
  reload_opsview => true
}

opsview_hostcheckcommand{'example-checkcommand':
  plugin => 'check_icmp',
  arguments => '-H $HOSTADDRESS$'
}

Opsview_hostgroup{
  ensure => present,
  reload_opsview => true
}

opsview_hostgroup{'example-parent':}
opsview_hostgroup{'example-linux':
  parent => 'example-parent'
}
opsview_hostgroup{'example-networking':
  parent => 'example-parent'
}

Opsview_hosttemplate{
  ensure => present,
  reload_opsview => true,
  description => "Created by Puppet"
}

opsview_hosttemplate{'example-other':
  description => "Other service checks",
  servicechecks => [ 'Connectivity - LAN',
                     { name => 'HTTP', 'event_handler' => 'eventhandler.sh', 'exception' => '-H www.opsview.com -S', 'timed_exception' => { 'args' => '-H www.google.com', 'timeperiod' => { 'name' => 'example-exception-timeperiod'} } }
		   ]

}
opsview_hosttemplate{'example-snmppolling':
  description => "Example SNMP polling service checks",
  management_urls => [
                       { 'name' => 'Web console', 'url' => 'http://$HOSTADDRESS$' }
                     ]
}
opsview_hosttemplate{'example-snmptraps':
  description => "Example SNMP trap service checks"
}

Opsview_notificationmethod{
  ensure => present,
  reload_opsview => true,
  run_on_master => true
}

opsview_notificationmethod{'example-notificationmethod':
  active => true,
  command => 'notify_by_email',
  user_variables => ['EMAIL']
}

Opsview_notificationprofile{
  ensure => present,
  reload_opsview => true
}
opsview_notificationprofile{'example-contact|Working Day':
  notification_period => 'workhours',
  host_notification_options => 'd,u,r,f',
  service_notification_options => 'w,c,f,r,u',
  all_hostgroups => true,
  all_servicegroups => true,
  notification_methods => ['Email', 'example-notificationmethod']
}

opsview_notificationprofile{'example-contact|On-call':
  notification_period => 'nonworkhours',
  host_notification_options => 'd,u,r,f',
  service_notification_options => 'c,f,r',
  all_hostgroups => false,
  all_servicegroups => false,
  notification_methods => ['Email'],
  hashtags => ['example-hashtag']
}

Opsview_role{
  ensure => present,
  reload_opsview => true
}

opsview_role{'example-role':
  all_hostgroups => false,
  all_servicegroups => true,
  all_hashtags => false,
  all_monitoringservers => true,
  access => ['VIEWALL','TESTALL','BSM','CONFIGUREBSM'],
  hostgroups => ['example-linux','example-networking'],
  configure_hostgroups => ['example-parent'],
  servicegroups => ['example-other','example-snmppolling','example-snmptraps'],
  hashtags => ['example-hashtag','example-public-hashtag'],
  business_services => [{'name' => 'Company Website', 'edit' => "true"},{'name' => 'Sales', 'edit' => "false"}]
}

Opsview_servicecheck{
  ensure => present,
  reload_opsview => true,
  description => 'Example Puppet service check',
  alert_every_failure => disable,
  event_handler_always_execute => false,
  flap_detection => true,
  hashtags => ['example-public-hashtag','example-hashtag'],
  markdown_filter => false,
  notification_options => 'w,c,r,u,f',
  record_output_changes => '',
  renotification_interval => '60m',
  servicegroup => 'example-other'
}

opsview_servicecheck{'Example - ActiveCheck':
  checktype => 'Active Plugin',
  plugin => 'check_nrpe',
  arguments => '-H localhost',
  dependencies => ['Opsview Agent'],
  check_interval => '5m',
  retry_check_interval => '1m',
  maximum_check_attempts => '3',
  check_period => '',
  notification_period => '',
  renotification_interval => '',
  invert_plugin_results => false,
  sensitive_arguments => '1'
}

opsview_servicecheck{'Example - PassiveCheck':
  checktype => 'Passive',
  variable => 'PUPPETVARIABLE',
  notification_options => 'w,c',
  event_handler => '',
  event_handler_always_execute => false,
}

opsview_servicecheck{'Example - SNMPCheck':
  checktype => 'SNMP Polling',
  hosttemplates => ['example-snmppolling'],
  notification_options => 'w,c',
  servicegroup => 'example-snmppolling',
  snmp_oid => '1.3.6',
  snmp_label => 'some_label',
  snmp_warning_comparison => '>',
  snmp_critical_comparison => equals,
  snmp_warning_value => '78',
  snmp_critical_value => '"88"'
}

opsview_servicecheck{'Example - SNMPTrap':
  checktype => 'SNMP trap',
  alert_every_failure => enable,
  hosttemplates => ['example-snmptraps'],
  freshness_action => "Submit Result",
  freshness_status => OK,
  freshness_text => 'No traps received in 10m. Reset to OK',
  freshness_timeout => '10m',
  record_output_changes => 'w,c,u',
  servicegroup => 'example-snmptraps',
  snmp_trap_rules => [
    { 'name' => 'rule 1', 'rule' => '1', 'action' => 'Send Alert', 'alert_level' => 'WARNING', 'message' => 'This is my trap'},
    { 'name' => 'rule 2', 'rule' => '1 && 1', 'action' => 'Stop Processing'}
  ]
}

Opsview_servicegroup{
  ensure => present,
  reload_opsview => true
}

opsview_servicegroup{'example-other':}
opsview_servicegroup{'example-snmppolling':}
opsview_servicegroup{'example-snmptraps':}


Opsview_timeperiod{
  ensure => present,
  reload_opsview => true,

  sunday => '00:00-24:00',
  monday => '09:00-17:00',
  tuesday => '09:00-17:00',
  wednesday => '09:00-17:00',
  thursday => '09:00-17:00',
  friday => '09:00-17:00',
  saturday => '00:00-24:00'
}

opsview_timeperiod{'example-exception-timeperiod':
  tuesday => '03:00-06:00,09:00-15:55'
}

Opsview_variable{
  ensure => present,
  reload_opsview => true
}

opsview_variable{'PUPPETVARIABLE':
  value => "",
  arg1 => "admin",
  encrypted_arg2 => "bdd4dcdb1375a56dff0bbe2d9ce47272b7ecc64d90737bffa5dabf6f0a87080f",
  label1 => "username",
  label2 => "password"
}




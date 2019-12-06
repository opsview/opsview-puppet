<span id="title-text"> [Deprecated] Opsview Puppet Module </span>
=======================================================================

Introduction
============

The Opsview Puppet module allows for the synchronization of Opsview configuration using Opsview’s REST API service and is divided into many types, each of which is focused on a specific area of the Opsview configuration.

NOTE: You will need to install the 'rest-client' Ruby library to use this module.  If you use your vendor-packaged version of Puppet, then you can either use the vendor's version of this library, or use 'gem install rest-client'.  However, if you use the PuppetLab's version then you will need to install development tools (such as gcc and make, amoungst others) and then use `/opt/puppetlabs/puppet/bin/gem install rest-client` to ensure the library and its prerequisites are installed to the correct location.

Configuration
=============

The puppet module should be installed into the standard location for Puppet modules, depending on the particular version of Puppet that you have. For example, this might be /etc/puppet/modules

After installing the module, you will need to create a file located at /etc/puppet/opsview.conf that contains the URL, username, and password for connecting to the Opsview system’s REST API.

**/etc/puppet/opsview.conf**

``` syntaxhighlighter-pre
url: http://opsview-master/rest
username: admin
password: initial
```

Puppet Types
============

All puppet types take two parameters

| Parameter       | Description                                                 | Type    |
|-----------------|-------------------------------------------------------------|---------|
| name            | Name of the object                                          | String  |
| reload\_opsview | Puppet will perform a reload at the end of the sync process | Boolean |

 

opsview\_bsmcomponent
---------------------

| Property         | Description                                  | Type             |
|------------------|----------------------------------------------|------------------|
| hosts            | Hosts that make up the component             | Array of strings |
| host\_template   | Host template that the component is built on | String           |
| required\_online | How many hosts are required to be online     | String           |

### Examples

``` syntaxhighlighter-pre
opsview_bsmcomponent{'example-component':
  ensure => present,
  reload_opsview => true,
  hosts => ['hostA','hostB','hostC'],
  host_template => 'Network - Base',
  required_online => '2'
}
```

 

opsview\_bsmservice
-------------------

| Property   | Description                             | Type             |
|------------|-----------------------------------------|------------------|
| components | Components that make up the BSM service | Array of strings |

 

### Examples

``` syntaxhighlighter-pre
opsview_bsmservice{'example-bsmservice':
  ensure => present,
  reload_opsview => true,
  components => ['componentA','componentB','componentC']
}
```

opsview\_contact
----------------

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">description</td>
<td align="left">Provides more information about the contact</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">full_name</td>
<td align="left">Full name for the contact. Defaults to the name of the contact</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">homepage_id</td>
<td align="left"><p>An ID number that identifies which navigation icon is the home icon.</p>
<p>ID &quot;2&quot; is for the &quot;Host groups, hosts, and service view&quot;</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">language</td>
<td align="left"><p>Which language to use in the UI.<br />
&quot;&quot; - Default browser setting<br />
&quot;en&quot; - English</p>
<p>&quot;de&quot; - German</p>
<p>&quot;es&quot; - Spanish </p></td>
<td align="left">String </td>
</tr>
<tr class="odd">
<td align="left">password</td>
<td align="left"><p>Password for the contact.</p>
<p>You can generate the encrypted value by running:</p>
<p>openssl passwd -apr1 &lt;password&gt;</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">realm</td>
<td align="left">The realm of the contact. Normally, this is 'local' or 'ldap'</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">shared_notification_profiles</td>
<td align="left">List of shared notification profiles that the contact is subscribed to</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">tips</td>
<td align="left">Controls if pop-up help windows appear when navigating new areas</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">variables</td>
<td align="left">List of contact variables that the contact uses</td>
<td align="left">Array of hashes</td>
</tr>
</tbody>
</table>

### Examples

``` syntaxhighlighter-pre
opsview_contact{'example-contact':
  description => 'Java developer',
  full_name => 'John Smith',
  homepage_id => '2',
  language => 'en',
  password => '$apr1$ADd0/BNL$XVPQgWENB6Bzg/M4QEZe20',
  realm => 'local',
  shared_notification_profiles => ['on-call'],
  tips => true,
  variables => [
                 {'name' => 'EMAIL', 'value' => 'your@email.com'},
                 {'name' => 'RSS_COLLAPSED', 'value' => '1'},
                 {'name' => 'RSS_MAXIMUM_AGE', 'value' => '1440'},
                 {'name' => 'RSS_MAXIMUM_ITEMS', 'value' => '30'}
  ]
```

opsview\_hashtag
----------------

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">all_hosts</td>
<td align="left">Globally tag all hosts with this hashtag</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">all_servicechecks</td>
<td align="left">Globally tag all service checks with this hashtag</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">description</td>
<td align="left">Provides a description for the hashtag</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">exclude_handled</td>
<td align="left">Do not consider handled service checks when calculating the overall hashtag state</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">hosts</td>
<td align="left">List of hosts to tag</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">public</td>
<td align="left">Whether the hashtag is public (can view without logging in to Opsview)</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">servicechecks</td>
<td align="left">List of service checks to tag</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">show_contextual_menus</td>
<td align="left">Whether to display contextual menus</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">style</td>
<td align="left"><p>Display style for the hashtag detail view.</p>
<p>Available values:</p>
<p>group_by_host</p>
<p>group_by_service</p>
<p>host_summary</p>
<p>errors_and_host_cells</p>
<p>performance</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">visible</td>
<td align="left">Whether the hashtag is included on the status pages or not</td>
<td align="left">Boolean</td>
</tr>
</tbody>
</table>

 

### Examples

``` syntaxhighlighter-pre
opsview_hashtag{'example-hashtag':
  all_hosts => false,
  all_servicechecks => true,
  description => 'My Opsview service checks',
  exclude_handled => true,
  hosts => ['opsview'],
  servicechecks => [],
  show_contextual_menus => true,
  style => "group_by_host",
  visible => true
}
```

``` syntaxhighlighter-pre
opsview_hashtag{'example-hashtag':
  all_hosts => true,
  all_servicechecks => false,
  description => 'MySQL checks',
  servicechecks => ['MySQL DB Listener','MySQL DB Processes']
}
```

opsview\_hostcheckcommand
-------------------------

| Property  | Description          | Type   |
|-----------|----------------------|--------|
| arguments | The plugin arguments | String |
| plugin    | The plugin to use    | String |

### Examples

``` syntaxhighlighter-pre
opsview_hostcheckcommand{'example-hostcheckcommand':
  plugin => 'check_icmp',
  arguments => '-H $HOSTADDRESS$'
}
```

opsview\_hostgroup
------------------

| Property | Description           | Type   |
|----------|-----------------------|--------|
| parent   | The parent host group | String |

### Examples

``` syntaxhighlighter-pre
opsview_hostgroup{'example-hostgroup1':}
```

``` syntaxhighlighter-pre
opsview_hostgroup{'example-hostgroup2':
  parent => 'example-hostgroup1'
}
```

opsview\_host
-------------

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">check_attempts</td>
<td align="left">The number of check attempts to use when running the host check for the host</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">check_command</td>
<td align="left">The name of the host check command to run</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">check_interval</td>
<td align="left">How often to run the host check</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">check_period</td>
<td align="left">The name of the check period to use</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">Description</td>
<td align="left">Provides a description of the host</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">enable_rancid</td>
<td align="left">Whether to enable the RANCID (Netaudit) module</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">enable_snmp</td>
<td align="left">Whether to enable SNMP</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">event_handler</td>
<td align="left">The name of the event handler to run when the host check changes state</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">event_handler_always_execute</td>
<td align="left">Whether to enable 'always execute' for event handlers</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">flap_detection</td>
<td align="left">Whether flap detection is enabled</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">hashtags</td>
<td align="left">List of hashtags to tag against the host</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">hostgroup</td>
<td align="left">Name of the host group to put the host in</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">hosttemplates</td>
<td align="left">List of host templates to apply to the host</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">icon</td>
<td align="left">The host icon to use</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">ip</td>
<td align="left">The address or hostname of the host</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">monitored_by</td>
<td align="left">The name of the monitoring server that the host uses</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">notification_options</td>
<td align="left"><p>Defines which states are allowed to notify for host notifications.</p>
<p>Format is a comma-separated list of the letters d, u, r, or f</p>
<p>d - DOWN</p>
<p>u - UNREACHABLE</p>
<p>r - RECOVERY</p>
<p>f - FLAPPING</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">notification_period</td>
<td align="left">The name of the notification period to use</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">other_addresses</td>
<td align="left"><p>List of additional IP addresses that the host has.</p>
<p>Format is a comma-separated list of IP addresses</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">parents</td>
<td align="left">List of parents for the host</td>
<td align="left">Array of strings</td>
</tr>
<tr class="odd">
<td align="left">rancid_autoenable</td>
<td align="left">Whether to set 'autoenable' mode for RANCID</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">rancid_connection_type</td>
<td align="left"><p>The connection method for RANCID.</p>
<p>Values are:</p>
<p>ssh</p>
<p>telnet</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">rancid_password</td>
<td align="left"><p>Password for the RANCID user.</p>
<p>You can generate the encrypted value by running:</p>
<p>opsview_crypt</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">rancid_username</td>
<td align="left">The RANCID user to connect as</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">rancid_vendor</td>
<td align="left"><p>Name of the RANCID vendor to use</p>
<p>Values are:</p>
<p>AGM<br />
Alteon<br />
Baynet<br />
Cat5<br />
Cisco<br />
Ellacoya<br />
Enterasys<br />
ERX<br />
Extreme<br />
EZT3<br />
Force10<br />
Foundry<br />
Hitachi<br />
HP<br />
Juniper<br />
MRTD<br />
Netscaler<br />
Netscreen<br />
Procket<br />
Redback<br />
Riverstone<br />
SMC<br />
TNT<br />
Zebra</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">renotification_interval</td>
<td align="left"><p>How often to resend alerts.</p>
<p>Format is [NUMBER1][UNIT1] [NUMBER2][UNIT2] .. [NUMBERn][UNITn]</p>
<p>where UNIT can be s (seconds), m (minutes), h (hours), or d (days)</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">retry_check_interval</td>
<td align="left">How long to wait before attempting a host check again</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">servicechecks</td>
<td align="left"><p>The service checks to set for the host. This includes options for setting event handlers, exceptions, and timed exceptions.</p>
<p>If you aren't interested in setting event handlers, exceptions, or timed exceptions, you can simply supply a string with the name of the service check.</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>[&#39;servicecheck1&#39;,&#39;servicecheck2&#39;]</code></pre>
</div>
</div>
<p>To set the advanced fields, you will need to make use of a hash as seen below:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>{ name =&gt; &#39;SERVICECHECKNAME&#39;, &#39;event_handler&#39; =&gt; &#39;EVENTHANDLERNAME&#39;, &#39;exception&#39; =&gt; &#39;EXCEPTIONARGUMENTS&#39;, &#39;timed_exception&#39; =&gt; { &#39;args&#39; =&gt; &#39;TIMEDEXCEPTIONARGUMENTS&#39;, &#39;timeperiod&#39; =&gt; { &#39;name&#39; =&gt; &#39;TIMEPERIODNAME&#39;} } }</code></pre>
</div>
</div>
<p>These two different types can be combined:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>[ &#39;Connectivity - LAN&#39;,
  { name =&gt; &#39;HTTP&#39;, &#39;event_handler&#39; =&gt; &#39;eventhandler.sh&#39;, &#39;exception&#39; =&gt; &#39;-H www.opsview.com -S&#39;, &#39;timed_exception&#39; =&gt; { &#39;args&#39; =&gt; &#39;-H www.google.com&#39;, &#39;timeperiod&#39; =&gt; { &#39;name&#39; =&gt; &#39;example-exception-timeperiod&#39;} } }
]</code></pre>
</div>
</div></td>
<td align="left"><p>Array of strings</p>
<p>and/or</p>
<p>Array of hashes</p></td>
</tr>
<tr class="odd">
<td align="left">snmp_community</td>
<td align="left"><p>Community string for the device.</p>
<p>You can generate the encrypted value by running:</p>
<p>opsview_crypt</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">snmp_extended_throughput_data</td>
<td align="left"> </td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">snmp_interfaces</td>
<td align="left"><p> </p>
<p>List of SNMP interfaces to monitor. This includes the thresholds for throughput, errors, and discards.</p>
<p>Note: The default thresholds are set using an interface name of &quot;&quot;</p>
<p>Note: Setting a threshold value to '-' will disable it and &quot;&quot; will use the default value.</p>
<p>Example input:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>[ 
  {&quot;interface&quot; =&gt; &quot;&quot;, &quot;enabled&quot; =&gt; &quot;0&quot;, &quot;throughput_warning&quot; =&gt; &quot;-&quot;, &quot;throughput_critical&quot; =&gt; &quot;0:75%&quot;, &quot;errors_warning&quot; =&gt; &quot;-&quot;, &quot;errors_critical&quot; =&gt; &quot;10&quot;, &quot;discards_warning&quot; =&gt; &quot;-&quot;, &quot;discards_critical&quot; =&gt; &quot;10&quot; },
  {&quot;interface&quot;=&gt;&quot;Serial0/0&quot;, &quot;enabled&quot;=&gt;&quot;1&quot;, &quot;throughput_warning&quot;=&gt;&quot;&quot;, &quot;throughput_critical&quot; =&gt; &quot;&quot;, &quot;errors_warning&quot; =&gt; &quot;&quot;, &quot;errors_critical&quot; =&gt; &quot;&quot;, &quot;discards_warning&quot; =&gt; &quot;&quot;, &quot;discards_critical&quot; =&gt; &quot;&quot; }
]
</code></pre>
</div>
</div></td>
<td align="left">Array of hashes</td>
</tr>
<tr class="even">
<td align="left">snmp_message_size</td>
<td align="left"><p>The SNMP message size. Might need to be increased for certain devices to work properly.</p>
<p>Values can be:</p>
<p>default</p>
<p>1Kio</p>
<p>2Kio</p>
<p>4Kio</p>
<p>8Kio</p>
<p>16Kio</p>
<p>32Kio</p>
<p>64Kio</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">snmp_port</td>
<td align="left">UDP port for SNMP communication</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">snmp_use_getnext</td>
<td align="left"> </td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">snmp_use_ifname</td>
<td align="left"> </td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">snmp_version</td>
<td align="left"><p>Version of SNMP to use.</p>
<p>Values can be:</p>
<p>1</p>
<p>2c</p>
<p>3</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">snmp_ifdescr_level</td>
<td align="left"><p>Tidy up the interface names based on level - higher numbers tidy up more.</p>
<p>Values can be:</p>
<p>off</p>
<p>0</p>
<p>1</p>
<p>2</p>
<p>3</p>
<p>4</p>
<p>5</p>
<p>6</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">snmpv3_authentication_password</td>
<td align="left"><p>Password for SNMPv3 authentication.</p>
<p>You can generate the encrypted value by running:</p>
<p>opsview_crypt</p></td>
<td align="left">String </td>
</tr>
<tr class="odd">
<td align="left"> snmpv3_authentication_protocol</td>
<td align="left"><p>Protocol was SNMPv3 authentication.</p>
<p>Values can be:</p>
<p>md5</p>
<p>sha </p></td>
<td align="left">String </td>
</tr>
<tr class="even">
<td align="left">snmpv3_privacy_password</td>
<td align="left"><p> </p>
<p>Password for SNMPv3 privacy.</p>
<p>Values can be:</p>
<p>des</p>
<p>aes</p>
<p>aes128</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">snmpv3_username</td>
<td align="left">The SNMPv3 user to connect as</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">variables</td>
<td align="left"><p>Sets the host variables to use.</p>
<p>Example syntax:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>[
{ &#39;name&#39; =&gt; &#39;NAME_OF_VARIABLE1&#39;, &#39;value&#39; =&gt; &#39;VALUE&#39;, &#39;arg1&#39; =&gt; &#39;ARGUMENT1 VALUE&#39;, &#39;arg2&#39; =&gt; &#39;ARGUMENT2_VALUE&#39;, &#39;arg3&#39; =&gt; &#39;ARGUMENT3_VALUE&#39;, &#39;arg4&#39; =&gt; &#39;ARGUMENT4_VALUE&#39;},
{ &#39;name&#39; =&gt; &#39;NAME_OF_VARIABLE2&#39;, &#39;value&#39; =&gt; &#39;VALUE&#39;, &#39;arg1&#39; =&gt; &#39;ARGUMENT1 VALUE&#39;, &#39;arg2&#39; =&gt; &#39;ARGUMENT2_VALUE&#39;, &#39;arg3&#39; =&gt; &#39;ARGUMENT3_VALUE&#39;, &#39;arg4&#39; =&gt; &#39;ARGUMENT4_VALUE&#39;}
]</code></pre>
</div>
</div>
<p><span>For encrypted fields, you can change 'argX' to 'encrypted_argX' and supply the value with an encrypted string that can be generated using opsview_crypt</span></p></td>
<td align="left">Array of hashes</td>
</tr>
</tbody>
</table>

### Examples

``` syntaxhighlighter-pre
 opsview_host{'example-host':
  ip => 'localhost',
  other_addresses => '127.0.0.1',
  hostgroup => 'Opsview',
  icon => 'LOGO - Linux Penguin',
  hosttemplates => ['Network - Base', 'OS - Unix Base'],
  servicechecks => ['Opsview Application Status'],
  check_command => 'ping',
  check_attempts => 2,
  check_period => '24x7',
  notification_period => '24x7',
  check_interval => '5m',
  renotification_interval => '60m',
  retry_check_interval => '10m',
  parents => ['opsview'],
  variables => [ 
                 {"name" => "DISK", "value" => "/" },
                 {"name" => "DISK", "value" => "/tmp", "arg1" => "-w 3% -c 1%"}
               ]  
}
```

opsview\_hosttemplate
---------------------

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">description</td>
<td align="left">Describes what the host template is for</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">hosts</td>
<td align="left">List of hosts to include as part of the template</td>
<td align="left">Array of strings</td>
</tr>
<tr class="odd">
<td align="left">management_urls</td>
<td align="left"><p>List of management URL's.</p>
<p>Format for the hash is:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>{ &#39;name&#39; =&gt; &#39;URLNAME&#39;, &#39;url&#39; =&gt; &#39;URL ADDRESs&#39; }</code></pre>
</div>
</div>
<p>i.e.</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code> { &#39;name&#39; =&gt; &#39;Web console&#39;, &#39;url&#39; =&gt; &#39;http://$HOSTADDRESS$&#39; }</code></pre>
</div>
</div></td>
<td align="left">Array of hashes</td>
</tr>
<tr class="even">
<td align="left">servicechecks</td>
<td align="left"><p>The service checks to set for the host. This includes options for setting event handlers, exceptions, and timed exceptions.</p>
<p>If you aren't interested in setting event handlers, exceptions, or timed exceptions, you can simply supply a string with the name of the service check.</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>[&#39;servicecheck1&#39;,&#39;servicecheck2&#39;]</code></pre>
</div>
</div>
<p><span>To set the advanced fields, you will need to make use of a hash as seen below:</span></p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>{ name =&gt; &#39;SERVICECHECKNAME&#39;, &#39;event_handler&#39; =&gt; &#39;EVENTHANDLERNAME&#39;, &#39;exception&#39; =&gt; &#39;EXCEPTIONARGUMENTS&#39;, &#39;timed_exception&#39; =&gt; { &#39;args&#39; =&gt; &#39;TIMEDEXCEPTIONARGUMENTS&#39;, &#39;timeperiod&#39; =&gt; { &#39;name&#39; =&gt; &#39;TIMEPERIODNAME&#39;} } }</code></pre>
</div>
</div>
<p><span>These two different types can be combined:</span></p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>[ &#39;Connectivity - LAN&#39;,
  { name =&gt; &#39;HTTP&#39;, &#39;event_handler&#39; =&gt; &#39;eventhandler.sh&#39;, &#39;exception&#39; =&gt; &#39;-H www.opsview.com -S&#39;, &#39;timed_exception&#39; =&gt; { &#39;args&#39; =&gt; &#39;-H www.google.com&#39;, &#39;timeperiod&#39; =&gt; { &#39;name&#39; =&gt; &#39;example-exception-timeperiod&#39;} } }
]</code></pre>
</div>
</div></td>
<td align="left">Array of hashes</td>
</tr>
</tbody>
</table>

opsview\_notificationmethod
---------------------------

| Property        | Description                                                     | Type             |
|-----------------|-----------------------------------------------------------------|------------------|
| active          | Whether the notification method is enabled or not               | Boolean          |
| command         | The name of the script to run and any additional arguments      | String           |
| run\_on\_master | Whether the notification method should run on the master or not | Boolean          |
| user\_variables | List of user variables to use for the notification method       | Array of strings |

 

### <span style="white-space: pre-wrap;">Examples</span>

``` syntaxhighlighter-pre
 opsview_notificationmethod{'example-notificationmethod':
  active => true,
  command => 'notify_by_email',
  run_on_master => true,
  user_variables => ['EMAIL']
}
```

<span style="white-space: pre-wrap;">opsview\_notificationprofile</span>
------------------------------------------------------------------------

<span style="white-space: pre-wrap;">Note: The format for the name of a notification profile is 'CONTACTNAME|PROFILENAME'</span>

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><p>all_business_components</p></td>
<td align="left">Whether to notify for all BSM components</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">all_business_services</td>
<td align="left">Whether to notify for all BSM services</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">all_hostgroups</td>
<td align="left">Whether to notify for all host groups</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">all_hashtags</td>
<td align="left">Whether to notify for all hashtags</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">all_servicegroups</td>
<td align="left">Whether to notify for all service groups</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">business_component_availability_below</td>
<td align="left">Threshold value for component availability</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">business_component_notification_options</td>
<td align="left"><p>Defines which states are allowed to notify for BSM component notifications.</p>
<p>Format is a comma-separated list of the letters f, i, a, or r</p>
<p>f - FAILED</p>
<p>i - IMPACTED</p>
<p>a - AVAILABILITY BELOW</p>
<p>r - RECOVERY</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">business_component_renotification_interval</td>
<td align="left"><p>How often to resend BSM component alerts.</p>
<p>Format is [NUMBER1][UNIT1] [NUMBER2][UNIT2] .. [NUMBERn][UNITn]</p>
<p>where UNIT can be s (seconds), m (minutes), h (hours), or d (days)</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">business_services</td>
<td align="left">List of business services</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">business_service_availability_below</td>
<td align="left"><span>Threshold value for component availability</span></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">business_service_notification_options</td>
<td align="left"><p>Defines which states are allowed to notify for BSM component notifications.</p>
<p>Format is a comma-separated list of the letters o, i, a, or r</p>
<p>o - OFFLINE</p>
<p>i - IMPACTED</p>
<p>a - AVAILABILITY BELOW</p>
<p>r - RECOVERY</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">business_service_renotification_interval</td>
<td align="left"><p>How often to resend BSM service alerts.</p>
<p>Format is [NUMBER1][UNIT1] [NUMBER2][UNIT2] .. [NUMBERn][UNITn]</p>
<p>where UNIT can be s (seconds), m (minutes), h (hours), or d (days)</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">hashtags</td>
<td align="left">List of hashtags to notify for</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">hostgroups</td>
<td align="left">List of host groups to notify for</td>
<td align="left">Array of strings</td>
</tr>
<tr class="odd">
<td align="left">host_notification_options</td>
<td align="left"><p>Defines which states are allowed to notify for host notifications.</p>
<p>Format is a comma-separated list of the letters d, u, r, or f</p>
<p>d - DOWN</p>
<p>u - UNREACHABLE</p>
<p><span>r - RECOVERY</span></p>
<p>f - FLAPPING</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">include_component_notes</td>
<td align="left">Whether to include component notes in the notification</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">include_service_notes</td>
<td align="left"><span>Whether to include service notes in the notification</span></td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">notification_methods</td>
<td align="left">List of notification methods to use</td>
<td align="left">Array of strings</td>
</tr>
<tr class="odd">
<td align="left">notification_period</td>
<td align="left">Name of the time period to use for notifications</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">send_from_alert</td>
<td align="left">When to start sending alerts. A value of &quot;1&quot; means right from the first alert.</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">servicegroups</td>
<td align="left">List of service groups to notify for</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">service_notification_options</td>
<td align="left"><p>Defines which states are allowed to notify for host notifications.</p>
<p>Format is a comma-separated list of the letters w, r, u, c, or f</p>
<p>w - WARNING</p>
<p>r - RECOVERY</p>
<p><span>u - UNKNOWN</span></p>
<p><span>c - CRITICAL</span></p>
<p>f - FLAPPING</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">stop_after_alert</td>
<td align="left">When to stop receiving alerts. A value of &quot;0&quot; means never.</td>
<td align="left">String</td>
</tr>
</tbody>
</table>

### <span style="white-space: pre-wrap;">Examples</span>

``` syntaxhighlighter-pre
 opsview_notificationprofile{'admin|Working Hours':
  notification_period => 'workhours',
  host_notification_options => 'd,u,r,f',
  service_notification_options => 'w,c,f,r,u',
  all_hostgroups => true,
  all_servicegroups => true,
  notification_methods => ['Email', 'RSS']
}
```

<span style="white-space: pre-wrap;">opsview\_role</span>
---------------------------------------------------------

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">access</td>
<td align="left">List of accesses for the role</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">all_bsm_components</td>
<td align="left">Whether the role can access BSM components</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">all_bsm_edit</td>
<td align="left">Whether the role can edit BSM</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">all_bsm_view</td>
<td align="left">Whether the role can view all BSM services</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">all_hostgroups</td>
<td align="left">Whether the role can view all host groups</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">all_hashtags</td>
<td align="left">Whether the role can view all hashtags</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">all_monitoringservers</td>
<td align="left">Whether the role can configure hosts to use all monitoring servers</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">all_servicegroups</td>
<td align="left">Whether the role can view all service groups</td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">business_services</td>
<td align="left"><p>List of business services that the role can access. You can also specify if the role can edit them.</p>
<p>Example of a business_service hash:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>{&#39;name&#39; =&gt; &#39;Company Website&#39;, &#39;edit&#39; =&gt; &quot;true&quot;},{&#39;name&#39; =&gt; &#39;Sales&#39;, &#39;edit&#39; =&gt; &quot;false&quot;}</code></pre>
</div>
</div></td>
<td align="left">Array of hashes</td>
</tr>
<tr class="even">
<td align="left">configure_hostgroups</td>
<td align="left">List of host groups that the role can configure.</td>
<td align="left">Array of strings</td>
</tr>
<tr class="odd">
<td align="left">hostgroups</td>
<td align="left">List of host groups that the role can view</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">monitoring_servers</td>
<td align="left">List of monitoring servers that the role can configure</td>
<td align="left">Array of strings</td>
</tr>
<tr class="odd">
<td align="left">servicegroups</td>
<td align="left">List of service groups that the role can view</td>
<td align="left">Array of strings</td>
</tr>
<tr class="even">
<td align="left">tenancy</td>
<td align="left">Name of the tenancy associated with the role</td>
<td align="left">String</td>
</tr>
</tbody>
</table>

### <span style="white-space: pre-wrap;">Examples</span>

``` syntaxhighlighter-pre
 opsview_role{'example-role':
  all_hostgroups => false,
  all_servicegroups => true,
  all_hashtags => false,
  all_monitoringservers => true,
  access => ['VIEWALL','TESTALL','BSM','CONFIGUREBSM'],
  hostgroups => ['Monitoring Servers','Opsview'],
  configure_hostgroups => ['opsview'],
  servicegroups => ['Application - Alfresco','Application - Apache HTTP Server','Service Provider - Amazon'],
  hashtags => ['example-hashtag','example-public-hashtag'],
  business_services => [
                         {'name' => 'Company Website', 'edit' => "true"},
                         {'name' => 'Sales', 'edit' => "false"}
                       ]
}
```

<span style="white-space: pre-wrap;">
</span>

<span style="color: rgb(49,48,48);font-family: calibri , arial , sans-serif;">opsview\_servicecheck</span>
----------------------------------------------------------------------------------------------------------

<table>
<colgroup>
<col width="25%" />
<col width="25%" />
<col width="25%" />
<col width="25%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
<th align="left">Check type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">alert_from_failure</td>
<td align="left"><p>Selects the behavior for dealing with service check alerts.</p>
<p> </p>
<p>Values can be:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>disable
enable
enable with re-notification interval</code></pre>
</div>
</div>
<p>or</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>0
1
2</code></pre>
</div>
</div>
<p>0 is &quot;disabled&quot;, 1 is &quot;enabled&quot;, and 2 is &quot;enable with re-notification interval&quot;</p></td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="even">
<td align="left">arguments</td>
<td align="left">Specifies the plugin arguments</td>
<td align="left">String</td>
<td align="left">Active</td>
</tr>
<tr class="odd">
<td align="left">cascaded_from</td>
<td align="left"><p>Specifies the name of an active service check that populates the passive check value.</p>
<p>This is used when &quot;re-checking&quot; a passive check.</p></td>
<td align="left">String</td>
<td align="left">Passive</td>
</tr>
<tr class="even">
<td align="left">checktype</td>
<td align="left"><p>The type of service check.</p>
<p>Values can be:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>Active Plugin
Passive
SNMP Polling
SNMP trap</code></pre>
</div>
</div></td>
<td align="left">String</td>
<td align="left">N/A</td>
</tr>
<tr class="odd">
<td align="left">check_freshness</td>
<td align="left">Whether to check the freshness of the service check</td>
<td align="left">Boolean</td>
<td align="left">Passive, SNMP trap</td>
</tr>
<tr class="even">
<td align="left">check_interval</td>
<td align="left">How often to run the service check</td>
<td align="left">String</td>
<td align="left">Active, SNMP Polling</td>
</tr>
<tr class="odd">
<td align="left">check_period</td>
<td align="left">The time period to use when running the service check</td>
<td align="left">String</td>
<td align="left">Active, SNMP Polling</td>
</tr>
<tr class="even">
<td align="left">dependencies</td>
<td align="left">List of service checks that this service check depends on</td>
<td align="left">Array of strings</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">description</td>
<td align="left">Description of the service check</td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="even">
<td align="left">event_handler</td>
<td align="left">The name of the event handler to run when the service check changes state</td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">event_handler_always_execute</td>
<td align="left"><span>Whether to enable 'always execute' for event handlers</span></td>
<td align="left">Boolean</td>
<td align="left">All</td>
</tr>
<tr class="even">
<td align="left">flap_detection</td>
<td align="left">Whether to enable flap detection</td>
<td align="left">Boolean</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">freshness_action</td>
<td align="left"><p>Action to take when freshness_timeout has been reached.</p>
<p>Values can be:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>Resend Notifications
Submit Result</code></pre>
</div>
</div></td>
<td align="left">String</td>
<td align="left">Passive, SNMP trap</td>
</tr>
<tr class="even">
<td align="left">freshness_status</td>
<td align="left"><p>The state to set when freshness_action is set to 'Submit Result'</p>
<p>Values can be:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>WARNING
CRITICAL
UNKNOWN
OK</code></pre>
</div>
</div></td>
<td align="left">String</td>
<td align="left">Passive, SNMP trap</td>
</tr>
<tr class="odd">
<td align="left">freshness_text</td>
<td align="left">The text to send when freshness_action is set to 'Submit Result'</td>
<td align="left">String</td>
<td align="left">Passive, SNMP trap</td>
</tr>
<tr class="even">
<td align="left">freshness_timeout</td>
<td align="left"> </td>
<td align="left">String</td>
<td align="left">Passive, SNMP trap</td>
</tr>
<tr class="odd">
<td align="left">hashtags</td>
<td align="left">List of hashtags to tag against the service check</td>
<td align="left">Array of strings</td>
<td align="left">All</td>
</tr>
<tr class="even">
<td align="left">hosttemplates</td>
<td align="left">List of host templates to assign this service check to</td>
<td align="left">Array of strings</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">invert_plugin_results</td>
<td align="left">Whether to invert plugin results</td>
<td align="left">Boolean</td>
<td align="left">Active</td>
</tr>
<tr class="even">
<td align="left">markdown_filter</td>
<td align="left">Whether to use the markdown filter</td>
<td align="left">Boolean</td>
<td align="left">Active</td>
</tr>
<tr class="odd">
<td align="left">maximum_check_attempts</td>
<td align="left">Maximum number of check attempts for the service check</td>
<td align="left">String</td>
<td align="left">Active, SNMP Polling</td>
</tr>
<tr class="even">
<td align="left">notification_options</td>
<td align="left"><p>Defines which states are allowed to notify for service check notifications.</p>
<p>Format is a comma-separated list of the letters w, c, r, u , f</p>
<p>w - WARNING</p>
<p>c - CRITICAL</p>
<p>u - UNKNOWN</p>
<p>r - RECOVERY</p>
<p>f - FLAPPING</p></td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">notification_period</td>
<td align="left">The time period to use for sending out notifications</td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="even">
<td align="left">record_output_changes</td>
<td align="left">Whether to record output changes for service checks that do not change state</td>
<td align="left">Boolean</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">renotification_interval</td>
<td align="left">How long to wait before sending an additional notification</td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="even">
<td align="left">retry_check_interval</td>
<td align="left">How long to wait before retrying a service check</td>
<td align="left">String</td>
<td align="left">Active, SNMP Polling</td>
</tr>
<tr class="odd">
<td align="left">sensitive_arguments</td>
<td align="left">Whether to hide sensitive arguments when displaying and running test checks</td>
<td align="left">Boolean</td>
<td align="left">Active</td>
</tr>
<tr class="even">
<td align="left">servicegroup</td>
<td align="left">Which service group to put the service check in</td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
<tr class="odd">
<td align="left">snmp_critical_comparison</td>
<td align="left"><p>The comparison function to use for the critical SNMP polling threshold.</p>
<p>Values can be:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>Numeric Comparison
==
&lt;
&gt;
separator
String Comparison
equals
not equals
regex</code></pre>
</div>
</div></td>
<td align="left">String</td>
<td align="left">SNMP Polling</td>
</tr>
<tr class="even">
<td align="left">snmp_critical_value</td>
<td align="left">The value to use for the SNMP polling critical threshold</td>
<td align="left">String</td>
<td align="left">SNMP Polling</td>
</tr>
<tr class="odd">
<td align="left">snmp_warning_comparison</td>
<td align="left"><p>The comparison function to use for the warning SNMP polling threshold.</p>
<p>Values can be:</p>
<div class="code panel pdl" style="border-width: 1px;">
<div class="codeContent panelContent pdl">
<pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: java; gutter: false; theme: Confluence" data-theme="Confluence"><code>Numeric Comparison
==
&lt;
&gt;</code></pre>
</div>
</div></td>
<td align="left">String</td>
<td align="left">SNMP Polling</td>
</tr>
<tr class="even">
<td align="left">snmp_warning_value</td>
<td align="left">The value to use for the SNMP polling warning threshold</td>
<td align="left">String</td>
<td align="left">SNMP Polling</td>
</tr>
<tr class="odd">
<td align="left">snmp_label</td>
<td align="left">The label to use for SNMP polling checks</td>
<td align="left">String</td>
<td align="left">SNMP Polling</td>
</tr>
<tr class="even">
<td align="left">snmp_oid</td>
<td align="left">The OID to use for SNMP polling checks</td>
<td align="left">String</td>
<td align="left">SNMP Polling</td>
</tr>
<tr class="odd">
<td align="left">snmp_trap_rules</td>
<td align="left">An array of hashes that represent trap rules</td>
<td align="left">Array of hashes</td>
<td align="left">SNMP trap</td>
</tr>
<tr class="even">
<td align="left">variable</td>
<td align="left">The variable to use in the service check</td>
<td align="left">String</td>
<td align="left">All</td>
</tr>
</tbody>
</table>

 

### <span style="color: rgb(49,48,48);font-family: calibri , arial , sans-serif;">Examples</span>

``` syntaxhighlighter-pre
opsview_servicecheck{'Example - ActiveCheck':
  checktype => 'Active Plugin',
  plugin => 'check_nrpe',
  arguments => '-H %PUPPETVARIABLE%',
  variable => 'PUPPETVARIABLE',
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
```

``` syntaxhighlighter-pre
opsview_servicecheck{'Example - PassiveCheck':
  checktype => 'Passive',
  notification_options => 'w,c',
  event_handler => '',
  event_handler_always_execute => false,
}
```

``` syntaxhighlighter-pre
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
```

``` syntaxhighlighter-pre
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
```

<span style="color: rgb(49,48,48);font-family: calibri , arial , sans-serif;">
</span>

<span style="color: rgb(49,48,48);font-family: calibri , arial , sans-serif;">opsview\_servicegroup</span>
----------------------------------------------------------------------------------------------------------

<span style="color: rgb(49,48,48);font-family: calibri , arial , sans-serif;">This property only needs a name</span>

### <span style="color: rgb(49,48,48);font-family: calibri , arial , sans-serif;">Examples</span>

``` syntaxhighlighter-pre
opsview_servicegroup{'example-servicegroup':}
```

opsview\_tenancy
----------------

| Property      | Description                              | Type   |
|---------------|------------------------------------------|--------|
| description   | Provides a description for the tenancy   | String |
| primary\_role | Name of the primary role for the tenancy | String |

### Examples

``` syntaxhighlighter-pre
opsview_tenancy{'example-tenancy':
  primary_role => 'View some, change none'
}
```

opsview\_timeperiod
-------------------

``` syntaxhighlighter-pre
time periods specified in the following format:
HH:MM-HH:MM[,HH:MM-HH:MM][...] Where HH are hours specified in 24 hour format.
 
Fields may be left blank to mean no time during this day
 
The times are based on the timezone of the Opsview server
 
Examples:00:00-09:00,17:30-24:00 - Midnight to 9am, and 5:30pm to midnight 
09:00-17:30 - 9am to 5:30pm 
00:00-24:00 - a full day 
```

| Property    | Description                                                      | Type   |
|-------------|------------------------------------------------------------------|--------|
| description | Provides a description for the time period                       | String |
| sunday      | Defines when the time period is active for this day              | String |
| monday      | <span>Defines when the time period is active for this day</span> | String |
| tuesday     | <span>Defines when the time period is active for this day</span> | String |
| wednesday   | <span>Defines when the time period is active for this day</span> | String |
| thursday    | <span>Defines when the time period is active for this day</span> | String |
| friday      | <span>Defines when the time period is active for this day</span> | String |
| saturday    | <span>Defines when the time period is active for this day</span> | String |

### Examples

``` syntaxhighlighter-pre
opsview_timeperiod{'example-timeperiod':
  description => 'Example Time Period',
  sunday => '00:00-24:00',
  monday => '09:00-17:00',
  tuesday => '09:00-17:00',
  wednesday => '09:00-17:00,19:00-22:15',
  thursday => '09:00-17:00',
  friday => '09:00-17:00',
  saturday => '00:00-24:00'
} 
```

opsview\_variable
-----------------

<table>
<colgroup>
<col width="33%" />
<col width="33%" />
<col width="33%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Property</th>
<th align="left">Description</th>
<th align="left">Type</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">arg1</td>
<td align="left">Value for the first argument</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">arg2</td>
<td align="left">Value for the second argument</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">arg3</td>
<td align="left">Value for the third argument</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">arg4</td>
<td align="left">Value for the fourth argument</td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">encrypted_arg1</td>
<td align="left"><p>Encrypted value for the first argument.</p>
<p>Use opsview_crypt to generate</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">encrypted_arg2</td>
<td align="left"><p>Encrypted value for the second argument.</p>
<p>Use opsview_crypt to generate</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">encrypted_arg3</td>
<td align="left"><p>Encrypted value for the third argument.</p>
<p>Use opsview_crypt to generate</p></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">encrypted_arg4</td>
<td align="left"><p>Encrypted value for the fourth argument.</p>
<p>Use opsview_crypt to generate</p></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">label1</td>
<td align="left">Description for the first argument</td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">label2</td>
<td align="left"><span>Description for the second argument</span></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">label3</td>
<td align="left"><span>Description for the third argument</span></td>
<td align="left">String</td>
</tr>
<tr class="even">
<td align="left">label4</td>
<td align="left"><span>Description for the fourth argument</span></td>
<td align="left">String</td>
</tr>
<tr class="odd">
<td align="left">secured1</td>
<td align="left">Make the first argument an encrypted field</td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">secured2</td>
<td align="left"><span>Make the second argument an encrypted field</span></td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">secured3</td>
<td align="left"><span>Make the third argument an encrypted field</span></td>
<td align="left">Boolean</td>
</tr>
<tr class="even">
<td align="left">secured4</td>
<td align="left"><span>Make the fourth argument an encrypted field</span></td>
<td align="left">Boolean</td>
</tr>
<tr class="odd">
<td align="left">value</td>
<td align="left">Value for the value field</td>
<td align="left">Boolean</td>
</tr>
</tbody>
</table>

 

### Examples

``` syntaxhighlighter-pre
opsview_variable{'EXAMPLE_VARIABLE':
  value => "",
  arg1 => "admin",
  encrypted_arg2 => "bdd4dcdb1375a56dff0bbe2d9ce47272b7ecc64d90737bffa5dabf6f0a87080f",
  label1 => "username",
  label2 => "password"
} 
```

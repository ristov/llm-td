#!/usr/bin/perl -w
#
# 7 templates detected by human analyst
#

$unprocessed = 0;

while (<STDIN>) {

  # template: snmpd[<*>]: IFLA_STATS for <*>
  # openchat: yes (snmpd[<*>]: IFLA_STATS for <*>)
  # drain: yes (snmpd[604]: IFLA_STATS for <*>), note that processID is 604 for all events
  # mistral: no (too generic template detected)
  # wizardlm2: yes (snmpd[<*>]: IFLA_STATS for <*>)

  if (/snmpd\[\d+\]: IFLA_STATS for (\S+)$/) {

    ++$data->{"ifla_stats"}->{"interface"}->{$1};

  }

  # template: snmpd[<*>]: [snmpd.NOTICE]: Got SNMP request from ip <*>
  # openchat: yes (snmpd[<*>]: [snmpd.NOTICE]: Got SNMP request from ip <*>)
  # drain: yes (<*> [snmpd.NOTICE]: Got SNMP request from ip <*>)
  # mistral: no (too generic template detected)
  # wizardlm2: yes (snmpd[<*>]: [snmpd.NOTICE]: Got SNMP request from ip <*>)

  elsif (/snmpd\[\d+\]: \[snmpd\.NOTICE\]: Got SNMP request from ip (\S+)$/) {

    ++$data->{"got_snmp_request"}->{"ip"}->{$1};

  }

  # template: snmpd[<*>]: ioctl <*> returned -1
  # openchat: yes (snmpd[<*>]: ioctl <*> returned -1)
  # drain: yes (<*> ioctl <*> returned -1)
  # mistral: no (too generic template detected)
  # wizardlm2: yes (snmpd[<*>]: ioctl <*> returned -1)

  elsif (/snmpd\[\d+\]: ioctl (\d+) returned -1$/) {

    ++$data->{"ioctl_error"}->{"number"}->{$1};

  }

  # template: snmpd[<*>]: [snmpd.ERR]: send response: Too long
  # openchat: yes (snmpd[<*>]: [snmpd.ERR]: send response: Too long)
  # drain: yes (<*> [snmpd.ERR]: send response: Too long)
  # mistral: no (too generic template detected)
  # wizardlm2: yes (snmpd[<*>]: [snmpd.ERR]: send response: Too long)

  elsif (/snmpd\[\d+\]: \[snmpd\.ERR\]: send response: (Too long)$/) {

    ++$data->{"send_response_error"}->{"message"}->{$1};

  }

  # template: snmpd[<*>]: [snmpd.ERR]: -- <*>
  # openchat: yes (snmpd[<*>]: [snmpd.ERR]:     -- SNMPv2-SMI::mib-<*>), note that mib=SNMPv2-SMI::mib-<*> for all events
  # drain: yes (<*> [snmpd.ERR]: -- <*>)
  # mistral: no (too generic template detected)
  # wizardlm2: yes (snmpd[<*>]: [snmpd.ERR]:     -- SNMPv2-SMI::<*>), note that mib=SNMPv2-SMI::<*> for all events

  elsif (/snmpd\[\d+\]: \[snmpd\.ERR\]:\s+-- (.+)$/) {

    ++$data->{"send_response_error_mib"}->{"mib"}->{$1};

  }

  # template: snmpd[<*>]: NET-SNMP version <*>
  # openchat: yes (snmpd[<*>]: NET-SNMP version 5.8), note that version=5.8 for all events
  # drain: yes (<*> NET-SNMP version 5.8), note that version=5.8 for all events
  # mistral: no (too generic template detected)
  # wizardlm2: no

  elsif (/snmpd\[\d+\]: NET-SNMP version (\S+)$/) {

    ++$data->{"net_snmp_start"}->{"version"}->{$1};

  }

  # template: snmpd[<*>]: error on subcontainer '<*>' insert (-1)
  # openchat: yes (snmpd[<*>]: error on subcontainer '<*>' insert (-1))
  # drain: no (two more specific templates detected)
  # mistral: no (too generic template detected)
  # wizardlm2: no

  elsif (/snmpd\[\d+\]: error on subcontainer '(.+)' insert \(-1\)$/) {

    ++$data->{"subcontainer error"}->{"container"}->{$1};

  }

  else {

    print STDERR $_;
    ++$unprocessed;

  }
}

foreach $event_type (sort keys %{$data}) {

  print "Event type: $event_type\n";

  foreach $field (sort keys %{$data->{$event_type}}) {

    print "\tField: $field\n"; 

    $i = 0;

    foreach $value (sort keys %{$data->{$event_type}->{$field}}) {

      print "\t\t$value = ", $data->{$event_type}->{$field}->{$value}, "\n";
      $i += $data->{$event_type}->{$field}->{$value};
    }

    print "\t\tTotal: $i events\n";
  }
}

print "\n\nUnprocessed lines: $unprocessed\n";

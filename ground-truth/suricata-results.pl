#!/usr/bin/perl -w
#
# 6 templates detected by human analyst
#

$unprocessed = 0;

while (<STDIN>) {

  # template: suricata[<*>]: [<*>] <*> [Classification: <*>] [Priority: <*>] {<*>} <*> -> <*>
  # openchat: no
  # drain: no

  if (/suricata\[\d+\]: \[(\S+)\] (.+?) \[Classification: (.+?)\] \[Priority: (\d+)\] \{(\S+)\} (\S+) -> (\S+)$/) {

    ++$data->{"suricata_alert"}->{"signature_id"}->{$1};
    ++$data->{"suricata_alert"}->{"alert_text"}->{$2};
    ++$data->{"suricata_alert"}->{"classification"}->{$3};
    ++$data->{"suricata_alert"}->{"priority"}->{$4};
    ++$data->{"suricata_alert"}->{"proto"}->{$5};
    ++$data->{"suricata_alert"}->{"source"}->{$6};
    ++$data->{"suricata_alert"}->{"destination"}->{$7};

  }

  # template: suricata[<*>]: [<*>] <Notice> -- rule reload starting
  # openchat: yes (suricata[<*>]: [<*>] <Notice> -- rule reload starting)
  # drain: no

  elsif (/suricata\[\d+\]: \[(\d+)\] <Notice> -- rule reload starting$/) {

    ++$data->{"rule_reload_starting"}->{"pid"}->{$1};

  }

  # template: suricata[<*>]: [<*>] <Notice> -- rule reload complete
  # openchat: yes (suricata[<*>]: [<*>] <Notice> -- rule reload complete)
  # drain: no

  elsif (/suricata\[\d+\]: \[(\d+)\] <Notice> -- rule reload complete$/) {

    ++$data->{"rule_reload_complete"}->{"pid"}->{$1};

  }

  # template: suricata[<*>]: [<*>] <Warning> -- [ERRCODE: SC_ERR_EVENT_ENGINE(210)] - can't suppress sid <*>, gid 1: unknown rule
  # openchat: yes (suricata[<*>]: [<*>] <Warning> -- [ERRCODE: SC_ERR_EVENT_ENGINE(210)] - can't suppress sid <*>, gid 1: unknown rule)
  # drain: yes (suricata[1701965]: [1701965] <Warning> -- [ERRCODE: SC_ERR_EVENT_ENGINE(210)] - can't suppress sid <*> gid 1: unknown rule), note that pid=1701965 for all events

  elsif (/suricata\[\d+\]: \[(\d+)\] <Warning> -- \[ERRCODE: SC_ERR_EVENT_ENGINE\(210\)\] - can't suppress sid (\d+), gid 1: unknown rule$/) {

    ++$data->{"suricata_cant_suppress_rule"}->{"pid"}->{$1};
    ++$data->{"suricata_cant_suppress_rule"}->{"ruleid"}->{$2};

  }

  # template: suricata[<*>]: [<*>] <Notice> -- Flow emergency mode entered...
  # openchat: no
  # drain: yes (suricata[1701965]: [1702042] <Notice> -- Flow emergency mode entered...), note that the only event that matches this template is reported as is

  elsif (/suricata\[\d+\]: \[(\d+)\] <Notice> -- Flow emergency mode entered\.\.\.$/) {

    ++$data->{"suricata_flow_emerg_mode_entered"}->{"pid"}->{$1};

  }

  # template: suricata[<*>]: [<*>] <Notice> -- Flow emergency mode over, back to normal... unsetting FLOW_EMERGENCY bit (ts.tv_sec: <*>, ts.tv_usec:<*>) flow_spare_q status(): <*>% flows at the queue
  # openchat: no
  # drain: yes (suricata[1701965]: [1702042] <Notice> -- Flow emergency mode over, back to normal... unsetting FLOW_EMERGENCY bit (ts.tv_sec: 1712598435, ts.tv_usec:781169) flow_spare_q status(): 433% flows at the queue), note that the only event that matches this template is reported as is

  elsif (/suricata\[\d+\]: \[(\d+)\] <Notice> -- Flow emergency mode over, back to normal\.\.\. unsetting FLOW_EMERGENCY bit \(ts\.tv_sec: \d+, ts\.tv_usec:\d+\) flow_spare_q status\(\): (\d+)% flows at the queue$/) {

    ++$data->{"suricata_flow_emerg_mode_over"}->{"pid"}->{$1};
    ++$data->{"suricata_flow_emerg_mode_over"}->{"queue_percent"}->{$2};

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

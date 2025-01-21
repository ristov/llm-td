#!/usr/bin/perl -w
#
# 7 templates identified by human analyst
#

$unprocessed = 0;

while (<STDIN>) {

  # template: apache2: PHP Notice: Constant <*> already defined in <*> on line <*>
  # openchat: no (too generic template, "Constant DAY" is detected as <*>)
  # drain: yes (apache2: PHP Notice: Constant DAY already defined in /var/www/html/time.php on line 7), note that constant=DAY, script=/var/www/html/time.php and line=7 for all events
  # mistral: no (too generic template detected)
  # wizardlm2: yes (apache2: PHP Notice: Constant DAY already defined in /var/www/html/time.php on line 7), note that constant=DAY, script=/var/www/html/time.php and line=7 for all events

  if (/apache2: PHP Notice:  Constant (\S+) already defined in (\S+) on line (\d+)$/) {

    ++$data->{"already_defined"}->{"constant"}->{$1};
    ++$data->{"already_defined"}->{"script"}->{$2};
    ++$data->{"already_defined"}->{"line"}->{$3};

  }

  # template: apache2: PHP Notice: Undefined offset: <*> in <*> on line <*>
  # openchat: yes (apache2: PHP Notice:  Undefined offset: <*> in <*> on line <*>)
  # drain: no (too generic template detected)
  # mistral: no (too generic template detected)
  # wizardlm2: yes (apache2: PHP Notice: Undefined offset: 11 in /var/www/html/main.php on line <*>), note that offset=11 and script=/var/www/html/main.php for all events

  elsif (/apache2: PHP Notice:  Undefined offset: (\d+) in (\S+) on line (\d+)$/) {

    ++$data->{"undefined_offset"}->{"offset"}->{$1};
    ++$data->{"undefined_offset"}->{"script"}->{$2};
    ++$data->{"undefined_offset"}->{"line"}->{$3};

  }

  # template: apache2: PHP Notice: Undefined variable: <*> in <*> on line <*>
  # openchat: yes (apache2: PHP Notice:  Undefined variable: <*> in <*> on line <*>)
  # drain: no (too generic template detected)
  # mistral: no (too generic template detected)
  # wizardlm2: no (several too specific templates detected)

  elsif (/apache2: PHP Notice:  Undefined variable: (\S+) in (\S+) on line (\d+)$/) {

    ++$data->{"undefined_variable"}->{"variable"}->{$1};
    ++$data->{"undefined_variable"}->{"script"}->{$2};
    ++$data->{"undefined_variable"}->{"line"}->{$3};

  }

  # template: apache2: PHP Notice: Undefined index: <*> in <*> on line <*>
  # openchat: yes (apache2: PHP Notice:  Undefined index: <*> in <*> on line <*>)
  # drain: no (too generic template detected)
  # mistral: no (too generic template detected)
  # wizardlm2: no

  elsif (/apache2: PHP Notice:  Undefined index: (\S+) in (\S+) on line (\d+)$/) {

    ++$data->{"undefined_index"}->{"index"}->{$1};
    ++$data->{"undefined_index"}->{"script"}->{$2};
    ++$data->{"undefined_index"}->{"line"}->{$3};

  }

  # template: apache2: PHP Warning: Invalid argument supplied for <*> in <*> on line <*>
  # openchat: yes (apache2: PHP Warning:  Invalid argument supplied for foreach() in <*> on line <*>), note that parameter="foreach()" for all events
  # drain: no (too generic template detected)
  # mistral: no (too generic template detected)
  # wizardlm2: no (too specific template detected with script=/var/www/html/overview.php)

  elsif (/apache2: PHP Warning:  Invalid argument supplied for (\S+) in (\S+) on line (\d+)$/) {

    ++$data->{"invalid_argument"}->{"parameter"}->{$1};
    ++$data->{"invalid_argument"}->{"script"}->{$2};
    ++$data->{"invalid_argument"}->{"line"}->{$3};

  }

  # template: apache2: PHP Warning: <*>: stat failed for <*> in <*> on line <*>
  # openchat: no (too generic template, "filesize(): stat" is detected as <*>)
  # drain: no (too generic template detected)
  # mistral: no (too generic template detected)
  # wizardlm2: no

  elsif (/apache2: PHP Warning:  (\S+): stat failed for (\S+) in (\S+) on line (\d+)$/) {

    ++$data->{"stat_failed"}->{"parameter1"}->{$1};
    ++$data->{"stat_failed"}->{"parameter2"}->{$2};
    ++$data->{"stat_failed"}->{"script"}->{$3};
    ++$data->{"stat_failed"}->{"line"}->{$4};

  }

  # template: apache2: PHP Warning: <*> expects exactly <*> parameters, <*> given in <*> on line <*>
  # openchat: yes (apache2: PHP Warning:  ob_flush() expects exactly 0 parameters, <*> given in <*> on line <*>), note that parameter="ob_flush()" and num1=0 for all events
  # drain: yes (apache2: PHP Warning: ob_flush() expects exactly 0 parameters, 1 given in /var/www/html/survey.php on line 229), note that parameter=ob_flush(), num1=0, num2=1, script=/var/www/html/survey.php and line=229 for all events
  # mistral: no (too generic template detected)
  # wizardlm2: yes (apache2: PHP Warning: ob_flush() expects exactly 0 parameters, 1 given in /var/www/html/survey.php on line 229), note that parameter=ob_flush(), num1=0, num2=1, script=/var/www/html/survey.php and line=229 for all events

  elsif (/apache2: PHP Warning:  (\S+) expects exactly (\d+) parameters, (\d+) given in (\S+) on line (\d+)$/) {

    ++$data->{"invalid_param"}->{"parameter"}->{$1};
    ++$data->{"invalid_param"}->{"num1"}->{$2};
    ++$data->{"invalid_param"}->{"num2"}->{$3};
    ++$data->{"invalid_param"}->{"script"}->{$4};
    ++$data->{"invalid_param"}->{"line"}->{$5};

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

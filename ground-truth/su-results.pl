#!/usr/bin/perl -w
#
# 13 templates in total identified by human analyst
#

$unprocessed = 0;

while (<STDIN>) {

  # template: su[<*>]: pam_unix(su:session): session opened for user <*> by <*>(uid=<*>)
  # openchat: no (the template 'su[<*>]: pam_unix(su:session): session opened for user root by <*>(uid=<*>)' does not cover events with target_user=postgres)
  # drain: no (the template '<*> pam_unix(su:session): session opened for user <*> by <*>' is too generic and also covers the next case)
  # mistral: yes (su[<*>]: pam_unix(su:session): session opened for user <*> by <*>(uid=<*>))
  # wizardlm2: no

  if (/su\[\d+\]: pam_unix\(su:session\): session opened for user (\S+) by (\S+)\(uid=(\d+)\)$/) {

    ++$data->{"pam_session_opened"}->{"target_user"}->{$1};
    ++$data->{"pam_session_opened"}->{"actor_user"}->{$2};
    ++$data->{"pam_session_opened"}->{"uid"}->{$3};

  }

  # template: su[<*>]: pam_unix(su:session): session opened for user <*> by (uid=<*>)
  # openchat: yes (su[<*>]: pam_unix(su:session): session opened for user <*> by (uid=<*>))
  # drain: no (the template '<*> pam_unix(su:session): session opened for user <*> by <*>' is too generic and also covers the previous case)
  # mistral: yes (su[<*>]: pam_unix(su:session): session opened for user <*> by (uid=<*>))
  # wizardlm2: no

  elsif (/su\[\d+\]: pam_unix\(su:session\): session opened for user (\S+) by \(uid=(\d+)\)$/) {

    ++$data->{"pam_session_opened2"}->{"target_user"}->{$1};
    ++$data->{"pam_session_opened2"}->{"uid"}->{$2};

  }

  # template: su[<*>]: pam_unix(su-l:session): session opened for user <*> by <*>(uid=<*>)
  # openchat: yes (su[<*>]: pam_unix(su-l:session): session opened for user <*> by <*>(uid=<*>))
  # drain: yes (<*> pam_unix(su-l:session): session opened for user <*> by <*>)
  # mistral: yes (su[<*>]: pam_unix(su-l:session): session opened for user <*> by <*>(uid=<*>))
  # wizardlm2: no

  elsif (/su\[\d+\]: pam_unix\(su-l:session\): session opened for user (\S+) by (\S+)\(uid=(\d+)\)$/) {

    ++$data->{"pam_loginsession_opened"}->{"target_user"}->{$1};
    ++$data->{"pam_loginsession_opened"}->{"actor_user"}->{$2};
    ++$data->{"pam_loginsession_opened"}->{"uid"}->{$3};

  }

  # template: su[<*>]: pam_unix(su:session): session closed for user <*>
  # openchat: yes (su[<*>]: pam_unix(su:session): session closed for user <*>)
  # drain: yes (<*> pam_unix(su:session): session closed for user <*>)
  # mistral: yes (su[<*>]: pam_unix(su:session): session closed for user <*>)
  # wizardlm2: yes (su[<*>]: pam_unix(su:session): session closed for user <*>)

  elsif (/su\[\d+\]: pam_unix\(su:session\): session closed for user (\S+)$/) {

    ++$data->{"pam_session_closed"}->{"user"}->{$1};

  }

  # template: su[<*>]: pam_unix(su-l:session): session closed for user <*>
  # openchat: yes (su[<*>]: pam_unix(su-l:session): session closed for user <*>)
  # drain: yes (<*> pam_unix(su-l:session): session closed for user <*>)
  # mistral: yes (su[<*>]: pam_unix(su-l:session): session closed for user <*>)
  # wizardlm2: no

  elsif (/su\[\d+\]: pam_unix\(su-l:session\): session closed for user (\S+)$/) {

    ++$data->{"pam_loginsession_closed"}->{"user"}->{$1};

  }

  # template: su[<*>]: Successful su for <*> by <*>
  # openchat: yes (su[<*>]: Successful su for <*> by <*>)
  # drain: yes (<*> Successful su for <*> by root), note that actor_user=root for all events
  # mistral: yes (su[<*>]: Successful su for <*> by <*>)
  # wizardlm2: no

  elsif (/su\[\d+\]: Successful su for (\S+) by (\S+)$/) {

    ++$data->{"successful_su"}->{"target_user"}->{$1};
    ++$data->{"successful_su"}->{"actor_user"}->{$2};

  }

  # template: su[<*>]: + <*> <*>:<*>
  # openchat: no (the template 'su[<*>]: + <*>' is too generic)
  # drain: no
  # mistral: yes (su[<*>]: + <*> <*>:<*>)
  # wizardlm2: no

  elsif (/su\[\d+\]: \+ (\S+) (\S+):(\S+)$/) {

    
    ++$data->{"successful_su2"}->{"terminal"}->{$1};
    ++$data->{"successful_su2"}->{"actor_user"}->{$2};
    ++$data->{"successful_su2"}->{"target_user"}->{$3};

  }

  # template: su[<*>]: FAILED su for <*> by <*>
  # openchat: yes (su[<*>]: FAILED su for <*> by <*>)
  # drain: yes (<*> FAILED su for mysql by alice), note that target_user=mysql and actor_user=alice for all events
  # mistral: no
  # wizardlm2: no

  elsif (/su\[\d+\]: FAILED su for (\S+) by (\S+)$/) {

    ++$data->{"failed_su"}->{"target_user"}->{$1};
    ++$data->{"failed_su"}->{"actor_user"}->{$2};

  }

  # template: su[<*>]: - <*> <*>:<*>
  # openchat: no (the template 'su[<*>]: - <*><*>' is too generic)
  # drain: yes (<*> - /dev/pts/0 alice:mysql), note that terminal=/dev/pts/0, actor_user=alice and target_user=mysql for all events
  # mistral: no
  # wizardlm2: no

  elsif (/su\[\d+\]: - (\S+) (\S+):(\S+)$/) {
    
    ++$data->{"failed_su2"}->{"terminal"}->{$1};
    ++$data->{"failed_su2"}->{"actor_user"}->{$2};
    ++$data->{"failed_su2"}->{"target_user"}->{$3};

  }

  # template: su[<*>]: (to <*>) <*> on <*>
  # openchat: yes (su[<*>]: (to <*>) <*> on <*>)
  # drain: no (several specific templates are detected)
  # mistral: yes (su[<*>]: (to <*>) <*> on pts/<*>), note that terminal=pts/<*> for all events
  # wizardlm2: no

  elsif (/su\[\d+\]: \(to (\S+)\) (\S+) on (\S+)$/) {
    
    ++$data->{"to_other_user"}->{"target_user"}->{$1};
    ++$data->{"to_other_user"}->{"actor_user"}->{$2};
    ++$data->{"to_other_user"}->{"terminal"}->{$3};

  }

  # template: su[<*>]: pam_systemd(su:session): Cannot create session: Already running in a session
  # openchat: yes (su[<*>]: pam_systemd(su:session): Cannot create session: Already running in a session)
  # drain: yes (<*> pam_systemd(su:session): Cannot create session: Already running in a session)
  # mistral: yes (su[<*>]: pam_systemd(su:session): Cannot create session: Already running in a session)
  # wizardlm2: no

  elsif (/su\[\d+\]: pam_systemd\(su:session\): Cannot create session: (Already running in a session)$/) {
    
    ++$data->{"pam_cant_create_session"}->{"message"}->{$1};

  }

  # template: su[<*>]: pam_authenticate: Authentication failure
  # openchat: yes (su[<*>]: pam_authenticate: Authentication failure)
  # drain: yes (<*> pam_authenticate: Authentication failure)
  # mistral: yes (su[<*>]: pam_authenticate: Authentication failure)
  # wizardlm2: no

  elsif (/su\[\d+\]: pam_authenticate: (Authentication failure)$/) {
    
    ++$data->{"pam_authentication_failure"}->{"message"}->{$1};

  }

  # template: su[<*>]: pam_unix(su:auth): auth could not identify password for [<*>]
  # openchat: yes (su[<*>]: pam_unix(su:auth): auth could not identify password for [<*>])
  # drain: yes (<*> pam_unix(su:auth): auth could not identify password for [mysql]), note that user=mysql for all events
  # mistral: no
  # wizardlm2: no

  elsif (/su\[\d+\]: pam_unix\(su:auth\): auth could not identify password for \[(\S+)\]$/) {
    
    ++$data->{"pam_no_password"}->{"user"}->{$1};

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

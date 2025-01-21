#!/usr/bin/perl -w
#
# 36 templates in total identified by human analyst 
#

$unprocessed = 0;

while (<STDIN>) {

  # template: sshd[<*>]: Accepted <*> for <*> from <*> port <*> ssh2
  # openchat: yes (sshd[<*>]: Accepted <*> for <*> from <*> port <*> ssh2)
  # drain: no (two more specific templates detected instead of one)
  # mistral: yes (sshd[<*>]: Accepted <*> for <*> from <*> port <*> ssh2)
  # wizardlm2: no

  if (/sshd\[\d+\]: Accepted (\S+) for (\S+) from (\S+) port (\d+) ssh2$/) {

    ++$data->{"ssh_login"}->{"auth_method"}->{$1};
    ++$data->{"ssh_login"}->{"user"}->{$2};
    ++$data->{"ssh_login"}->{"host"}->{$3};
    ++$data->{"ssh_login"}->{"port"}->{$4};

  }

  # template: sshd[<*>]: Accepted <*> for <*> from <*> port <*> ssh2: <*>
  # openchat: yes (sshd[<*>]: Accepted publickey for <*> from <*> port <*> ssh2: <*>), note that auth_method=publickey for all events
  # drain: yes (<*> Accepted publickey for <*> from <*> port <*> ssh2: <*> <*>), note that auth_method=publickey and 'data' field contains two words for all events
  # mistral: yes (sshd[<*>]: Accepted <*> for <*> from <*> port <*> ssh2: <*>)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Accepted (\S+) for (\S+) from (\S+) port (\d+) ssh2: (.+)$/) {

    ++$data->{"ssh_login2"}->{"auth_method"}->{$1};
    ++$data->{"ssh_login2"}->{"user"}->{$2};
    ++$data->{"ssh_login2"}->{"host"}->{$3};
    ++$data->{"ssh_login2"}->{"port"}->{$4};
    ++$data->{"ssh_login2"}->{"data"}->{$5};

  }

  # template: sshd[<*>]: Failed <*> for <*> from <*> port <*> ssh2
  # openchat: yes (sshd[<*>]: Failed password for <*> from <*> port <*> ssh2), note that auth_method=password for all events
  # drain: yes (<*> Failed password for <*> from <*> port <*> ssh2), note that auth_method=password for all events
  # mistral: yes (sshd[<*>]: Failed password for <*> from <*> port <*> ssh2), note that auth_method=password for all events
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Failed (\S+) for (\S+) from (\S+) port (\d+) ssh2$/) {

    ++$data->{"ssh_login_failed"}->{"auth_method"}->{$1};
    ++$data->{"ssh_login_failed"}->{"user"}->{$2};
    ++$data->{"ssh_login_failed"}->{"host"}->{$3};
    ++$data->{"ssh_login_failed"}->{"port"}->{$4};

  }

  # template: sshd[<*>]: Failed <*> for <*> from <*> port <*> ssh2: <*>
  # openchat: yes (sshd[<*>]: Failed password for <*> from <*> port <*> ssh2: <*>), note that auth_method=password for all events
  # drain: yes (sshd[20970]: Failed password for alice from 192.168.0.105 port 39202 ssh2: RSA SHA256:RDF/A9ol2oNtdGNllLjrpC708VyFNRmZTy10mnHCRpg), note that there is only one event matching that template which is reported as is
  # mistral: yes (sshd[<*>]: Failed password for <*> from <*> port <*> ssh2: <*>), note that auth_method=password for all events
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Failed (\S+) for (\S+) from (\S+) port (\d+) ssh2: (.+)$/) {

    ++$data->{"ssh_login_failed2"}->{"auth_method"}->{$1};
    ++$data->{"ssh_login_failed2"}->{"user"}->{$2};
    ++$data->{"ssh_login_failed2"}->{"host"}->{$3};
    ++$data->{"ssh_login_failed2"}->{"port"}->{$4};
    ++$data->{"ssh_login_failed2"}->{"data"}->{$5};

  }

  # template: sshd[<*>]: Failed <*> for invalid user <*> from <*> port <*> ssh2
  # openchat: yes (sshd[<*>]: Failed <*> for invalid user <*> from <*> port <*> ssh2)
  # drain: yes (<*> Failed none for invalid user edward from 192.168.0.89 port <*> ssh2), note that auth_method=none, user=edward and host=192.168.0.89 for all events
  # mistral: yes (sshd[<*>]: Failed <*> for invalid user <*> from <*> port <*> ssh2)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Failed (\S+) for invalid user (\S+) from (\S+) port (\d+) ssh2$/) {

    ++$data->{"ssh_login_failed_invalid_user"}->{"auth_method"}->{$1};
    ++$data->{"ssh_login_failed_invalid_user"}->{"user"}->{$2};
    ++$data->{"ssh_login_failed_invalid_user"}->{"host"}->{$3};
    ++$data->{"ssh_login_failed_invalid_user"}->{"port"}->{$4};

  }

  # template: sshd[<*>]: Invalid user <*> from <*>
  # openchat: yes (sshd[<*>]: Invalid user <*> from <*>)
  # drain: yes (sshd[10842]: Invalid user felixa from 192.168.3.232), note that there is only one line matching that template which is reported as is
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Invalid user (\S+) from (\S+)$/) {

    ++$data->{"ssh_invalid_user"}->{"user"}->{$1};
    ++$data->{"ssh_invalid_user"}->{"host"}->{$2};

  }

  # template: sshd[<*>]: Invalid user <*> from <*> port <*>
  # openchat: no
  # drain: yes (<*> Invalid user <*> from <*> port <*>)
  # mistral: yes (sshd[<*>]: Invalid user <*> from <*> port <*>)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Invalid user (\S+) from (\S+) port (\d+)$/) {

    ++$data->{"ssh_invalid_user_with_port"}->{"user"}->{$1};
    ++$data->{"ssh_invalid_user_with_port"}->{"host"}->{$2};
    ++$data->{"ssh_invalid_user_with_port"}->{"port"}->{$3};

  }

  # template: sshd[<*>]: input_userauth_request: invalid user <*>
  # openchat: yes (sshd[<*>]: input_userauth_request: invalid user <*>)
  # drain: no (two more specific templates are detected instead)
  # mistral: yes (sshd[<*>]: input_userauth_request: invalid user <*>)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: input_userauth_request: invalid user (.+)$/) {

    ++$data->{"ssh_input_userauth_request"}->{"data"}->{$1};

  }

  # template: sshd[<*>]: User <*> from <*> not allowed because none of user's groups are listed in AllowGroups
  # openchat: yes (sshd[<*>]: User <*> from <*> not allowed because none of user's groups are listed in AllowGroups)
  # drain: yes (<*> User root from srv31.example.com not allowed because none of user's groups are listed in AllowGroups), note that user=root and host=srv31.example.com for all events
  # mistral: yes (sshd[<*>]: User <*> from <*> not allowed because none of user's groups are listed in AllowGroups)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: User (\S+) from (\S+) not allowed because none of user's groups are listed in AllowGroups$/) {

    ++$data->{"ssh_user_not_allowed"}->{"user"}->{$1};
    ++$data->{"ssh_user_not_allowed"}->{"host"}->{$2};

  }

  # template: sshd[<*>]: Received disconnect from <*> port <*>:<*>
  # openchat: no
  # drain: no (several more specific templates are detected instead)
  # mistral: no (the template 'sshd[<*>]: Received disconnect from <*> port <*>:<*>: <*>' is close and detects the structure of the 'message' field as '<*>: <*>', but in the case of some events message="11:" and the trailing <*> does not match)
  # wizardlm2: yes (sshd[<*>]: Received disconnect from <*> port <*>:<*>)

  elsif (/sshd\[\d+\]: Received disconnect from (\S+) port (\d+):(.+)$/) {

    ++$data->{"ssh_received_disconnect_with_port"}->{"host"}->{$1};
    ++$data->{"ssh_received_disconnect_with_port"}->{"port"}->{$2};
    ++$data->{"ssh_received_disconnect_with_port"}->{"message"}->{$3};

  }

  # template: sshd[<*>]: Received disconnect from <*>:<*>
  # openchat: yes (sshd[<*>]: Received disconnect from <*>:<*>)
  # drain: yes (<*> Received disconnect from <*> 11: disconnected by user), note that message="11: disconnected by user" for all events
  # mistral: yes (sshd[<*>]: Received disconnect from <*>: <*>: <*>), note that the structure of the 'message' field is detected as ' <*>: <*>', and message=" 11: disconnected by user" for all events which matches ' <*>: <*>'
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Received disconnect from (\S+):(.+)$/) {

    ++$data->{"ssh_received_disconnect"}->{"host"}->{$1};
    ++$data->{"ssh_received_disconnect"}->{"message"}->{$2};

  }

  # template: sshd[<*>]: Disconnected from <*> port <*>
  # openchat: yes (sshd[<*>]: Disconnected from <*> port <*>)
  # drain: yes (<*> Disconnected from <*> port <*>)
  # mistral: yes (sshd[<*>]: Disconnected from <*> port <*>)
  # wizardlm2: yes (sshd[<*>]: Disconnected from <*> port <*>)
  
  elsif (/sshd\[\d+\]: Disconnected from (\S+) port (\d+)$/) {

    ++$data->{"ssh_disconnected"}->{"host"}->{$1};
    ++$data->{"ssh_disconnected"}->{"port"}->{$2};

  }

  # template: sshd[<*>]: Disconnected from user <*> <*> port <*>
  # openchat: no 
  # drain: yes (<*> Disconnected from user <*> <*> port <*>)
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Disconnected from user (\S+) (\S+) port (\d+)$/) {

    ++$data->{"ssh_disconnected_with_user"}->{"user"}->{$1};
    ++$data->{"ssh_disconnected_with_user"}->{"host"}->{$2};
    ++$data->{"ssh_disconnected_with_user"}->{"port"}->{$3};

  }

  # template: sshd[<*>]: Disconnected from <*> port <*> <*>
  # openchat: no 
  # drain: yes (<*> Disconnected from <*> port <*> [preauth]), note that data=[preauth] for all events
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Disconnected from (\S+) port (\d+) (\S+)$/) {

    ++$data->{"ssh_disconnected_with_data"}->{"host"}->{$1};
    ++$data->{"ssh_disconnected_with_data"}->{"port"}->{$2};
    ++$data->{"ssh_disconnected_with_data"}->{"data"}->{$3};

  }

  # template: sshd[<*>]: Disconnected from authenticating user <*> <*> port <*> <*>
  # openchat: no 
  # drain: yes (<*> Disconnected from authenticating user alice 192.168.3.250 port <*> [preauth]), note that user=alice, host=192.168.3.250 and data=[preauth] for all events
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Disconnected from authenticating user (\S+) (\S+) port (\d+) (\S+)$/) {

    ++$data->{"ssh_disconnected_auth_user"}->{"user"}->{$1};
    ++$data->{"ssh_disconnected_auth_user"}->{"host"}->{$2};
    ++$data->{"ssh_disconnected_auth_user"}->{"port"}->{$3};
    ++$data->{"ssh_disconnected_auth_user"}->{"data"}->{$4};

  }

  # template: sshd[<*>]: Connection closed by <*> <*>
  # openchat: yes (sshd[<*>]: Connection closed by <*> [preauth]), note that data=[preauth] for all events
  # drain: yes (<*> Connection closed by <*> [preauth]), note that data=[preauth] for all events
  # mistral: yes (sshd[<*>]: Connection closed by <*> [preauth]), note that data=[preauth] for all events
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Connection closed by (\S+) (\S+)$/) {

    ++$data->{"ssh_connection_closed"}->{"host"}->{$1};
    ++$data->{"ssh_connection_closed"}->{"data"}->{$2};

  }

  # template: sshd[<*>]: Connection closed by <*> port <*> <*>
  # openchat: no 
  # drain: yes (<*> Connection closed by <*> port <*> [preauth]), note that data=[preauth] for all events
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Connection closed by (\S+) port (\d+) (\S+)$/) {

    ++$data->{"ssh_connection_closed_with_port"}->{"host"}->{$1};
    ++$data->{"ssh_connection_closed_with_port"}->{"port"}->{$2};
    ++$data->{"ssh_connection_closed_with_port"}->{"data"}->{$3};

  }

  # template: sshd[<*>]: Connection closed by authenticating user <*> <*> port <*> <*>
  # openchat: no 
  # drain: yes (<*> Connection closed by authenticating user <*> <*> port <*> [preauth]), note that data=[preauth] for all events
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Connection closed by authenticating user (\S+) (\S+) port (\d+) (\S+)$/) {

    ++$data->{"ssh_connection_closed_with_user"}->{"user"}->{$1};
    ++$data->{"ssh_connection_closed_with_user"}->{"host"}->{$2};
    ++$data->{"ssh_connection_closed_with_user"}->{"port"}->{$3};
    ++$data->{"ssh_connection_closed_with_user"}->{"data"}->{$4};

  }

  # template: sshd[<*>]: Connection reset by authenticating user <*> <*> port <*> <*>
  # openchat: yes (sshd[<*>]: Connection reset by authenticating user <*> <*> port <*> [preauth]), note that data=[preauth] for all events
  # drain: yes (<*> Connection reset by authenticating user felix 192.168.3.232 port <*> [preauth]), note that user=felix, host 192.168.3.232 and data=[preauth] for all events
  # mistral: yes (sshd[<*>]: Connection reset by authenticating user <*> <*> port <*> [preauth]), note that data=[preauth] for all events
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Connection reset by authenticating user (\S+) (\S+) port (\d+) (\S+)$/) {

    ++$data->{"ssh_connection_reset"}->{"user"}->{$1};
    ++$data->{"ssh_connection_reset"}->{"host"}->{$2};
    ++$data->{"ssh_connection_reset"}->{"port"}->{$3};
    ++$data->{"ssh_connection_reset"}->{"data"}->{$4};

  }

  # template: sshd[<*>]: pam_unix(sshd:session): session opened for user <*> by (uid=<*>)
  # openchat: yes (sshd[<*>]: pam_unix(sshd:session): session opened for user <*> by (uid=<*>))
  # drain: yes (<*> pam_unix(sshd:session): session opened for user <*> by (uid=0)), note that uid=0 for all events
  # mistral: yes (sshd[<*>]: pam_unix(sshd:session): session opened for user <*> by (uid=<*>))
  # wizardlm2: yes (sshd[<*>]: pam_unix(sshd:session): session opened for user <*> by (uid=<*>))

  elsif (/sshd\[\d+\]: pam_unix\(sshd:session\): session opened for user (\S+) by \(uid=(\d+)\)$/) {

    ++$data->{"pam_session_opened"}->{"user"}->{$1};
    ++$data->{"pam_session_opened"}->{"uid"}->{$2};

  }

  # template: sshd[<*>]: pam_unix(sshd:session): session closed for user <*>
  # openchat: yes (sshd[<*>]: pam_unix(sshd:session): session closed for user <*>)
  # drain: yes (<*> pam_unix(sshd:session): session closed for user <*>)
  # mistral: yes (sshd[<*>]: pam_unix(sshd:session): session closed for user <*>)
  # wizardlm2: yes (sshd[<*>]: pam_unix(sshd:session): session closed for user <*>)

  elsif (/sshd\[\d+\]: pam_unix\(sshd:session\): session closed for user (\S+)$/) {

    ++$data->{"pam_session_closed"}->{"user"}->{$1};

  }

  # template: sshd[<*>]: pam_unix(sshd:auth): authentication failure; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*> user=<*>
  # openchat: yes (sshd[<*>]: pam_unix(sshd:auth): authentication failure; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*> user=<*>)
  # drain: yes (<*> pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= <*> <*>), note that uid=0 and euid=0 for all events, and 'rhost' and 'user' fields are not recognized
  # mistral: yes (sshd[<*>]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=<*> user=<*>), note that uid=0 and euid=0 for all events
  # wizardlm2: yes (sshd[<*>]: pam_unix(sshd:auth): authentication failure; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*>  user=<*>)

  elsif (/sshd\[\d+\]: pam_unix\(sshd:auth\): authentication failure; logname= uid=(\d+) euid=(\d+) tty=ssh ruser= rhost=(\S+)  user=(\S+)$/) {

    ++$data->{"pam_auth_failure"}->{"uid"}->{$1};
    ++$data->{"pam_auth_failure"}->{"euid"}->{$2};
    ++$data->{"pam_auth_failure"}->{"host"}->{$3};
    ++$data->{"pam_auth_failure"}->{"user"}->{$4};

  }

  # template: sshd[<*>]: PAM 1 more authentication failure; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*> user=<*>
  # openchat: no (the template 'sshd[<*>]: PAM <*> more authentication failure; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*> user=<*>' is very close, but instead of '1' there is '<*>')
  # drain: no (one generic template is detected that also captures the next)
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: PAM 1 more authentication failure; logname= uid=(\d+) euid=(\d+) tty=ssh ruser= rhost=(\S+)  user=(\S+)$/) {

    ++$data->{"pam_1more_auth_failure"}->{"uid"}->{$1};
    ++$data->{"pam_1more_auth_failure"}->{"euid"}->{$2};
    ++$data->{"pam_1more_auth_failure"}->{"host"}->{$3};
    ++$data->{"pam_1more_auth_failure"}->{"user"}->{$4};

  }

  # template: sshd[<*>]: PAM <*> more authentication failures; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*> user=<*>
  # openchat: yes (sshd[<*>]: PAM <*> more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=<*> user=<*>), note that uid=0 and euid=0 for all events
  # drain: no (one generic template is detected that also captures the previous)
  # mistral: no
  # wizardlm2: yes (sshd[<*>]: PAM 2 more authentication failures; logname= uid=<*> euid=<*> tty=ssh ruser= rhost=<*>  user=<*>), note that N=2 for all events

  elsif (/sshd\[\d+\]: PAM (\d+) more authentication failures; logname= uid=(\d+) euid=(\d+) tty=ssh ruser= rhost=(\S+)  user=(\S+)$/) {

    ++$data->{"pam_Nmore_auth_failures"}->{"N"}->{$1};
    ++$data->{"pam_Nmore_auth_failures"}->{"uid"}->{$2};
    ++$data->{"pam_Nmore_auth_failures"}->{"euid"}->{$3};
    ++$data->{"pam_Nmore_auth_failures"}->{"host"}->{$4};
    ++$data->{"pam_Nmore_auth_failures"}->{"user"}->{$5};

  }

  # template: sshd[<*>]: pam_systemd(sshd:session): Failed to release session: <*>
  # openchat: yes (sshd[<*>]: pam_systemd(sshd:session): Failed to release session: Interrupted system call), note that message="Interrupted system call" for all events
  # drain: yes (sshd[7173]: pam_systemd(sshd:session): Failed to release session: Interrupted system call), note that there is only one message matching that template which is reported as is
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: pam_systemd\(sshd:session\): Failed to release session: (.+)$/) {

    ++$data->{"pam_session_release_failure"}->{"message"}->{$1};

  }

  # template: sshd[<*>]: rexec line <*>: Deprecated option <*>
  # openchat: yes (sshd[<*>]: rexec line <*>: Deprecated option <*>)
  # drain: yes (<*> rexec line <*> Deprecated option <*>)
  # mistral: no (a more general template is detected that also covers following two templates)
  # wizardlm2: yes (sshd[<*>]: rexec line <*>: Deprecated option <*>)

  elsif (/sshd\[\d+\]: rexec line (\d+): Deprecated option (\S+)$/) {

    ++$data->{"rexec_line"}->{"line"}->{$1};
    ++$data->{"rexec_line"}->{"deprecated_option"}->{$2};

  }

  # template: sshd[<*>]: reprocess config line <*>: Deprecated option <*>
  # openchat: yes (sshd[<*>]: reprocess config line <*>: Deprecated option <*>)
  # drain: yes (<*> reprocess config line <*> Deprecated option <*>)
  # mistral: no (a more general template is detected that also covers the previous and next template)
  # wizardlm2: yes (sshd[<*>]: reprocess config line <*>: Deprecated option <*>)

  elsif (/sshd\[\d+\]: reprocess config line (\d+): Deprecated option (\S+)$/) {

    ++$data->{"reprocess_config_line"}->{"line"}->{$1};
    ++$data->{"reprocess_config_line"}->{"deprecated_option"}->{$2};

  }

  # template: sshd[<*>]: /etc/ssh/sshd_config line <*>: Deprecated option <*>
  # openchat: yes (sshd[<*>]: /etc/ssh/sshd_config line <*>: Deprecated option <*>)
  # drain: yes (<*> /etc/ssh/sshd_config line <*> Deprecated option <*>)
  # mistral: no (a more general template is detected that also covers previous two templates)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: \/etc\/ssh\/sshd_config line (\d+): Deprecated option (\S+)$/) {

    ++$data->{"sshd_config_line"}->{"line"}->{$1};
    ++$data->{"sshd_config_line"}->{"deprecated_option"}->{$2};

  }

  # template: sshd[<*>]: Server listening on <*> port <*>.
  # openchat: yes (sshd[<*>]: Server listening on <*> port <*>.)
  # drain: yes (<*> Server listening on <*> port 22.), note that port="22." for all events
  # mistral: no (two more specific templates are detected)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Server listening on (\S+) port (\d+)\.$/) {

    ++$data->{"server_listening"}->{"interface"}->{$1};
    ++$data->{"server_listening"}->{"port"}->{$2};

  }

  # template: sshd[<*>]: Did not receive identification string from <*>
  # openchat: yes (sshd[<*>]: Did not receive identification string from <*>)
  # drain: yes (<*> Did not receive identification string from <*>)
  # mistral: yes (sshd[<*>]: Did not receive identification string from <*>)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Did not receive identification string from (\S+)$/) {

    ++$data->{"no_identification_string"}->{"host"}->{$1};

  }

  # template: sshd[<*>]: Bad protocol version identification '<*>' from <*>
  # openchat: yes (sshd[<*>]: Bad protocol version identification '<*>' from <*>)
  # drain: yes (<*> Bad protocol version identification <*> from 192.168.3.141), note that host=192.168.3.141 for all events
  # mistral: yes (sshd[<*>]: Bad protocol version identification '<*>' from <*>)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Bad protocol version identification '(\S+)' from (\S+)$/) {

    ++$data->{"bad_protocol"}->{"protocol"}->{$1};
    ++$data->{"bad_protocol"}->{"host"}->{$2};

  }

  # template: sshd[<*>]: Protocol major versions differ for <*>: <*> vs. <*>
  # openchat: yes (sshd[<*>]: Protocol major versions differ for <*>: SSH-<*>-OpenSSH_<*> vs. SSH-<*>-OpenSSH_<*>), note that internal structure of protocol version strings is discovered
  # drain: yes (<*> Protocol major versions differ for 192.168.3.141: SSH-2.0-OpenSSH_5.3 vs. <*>), note that host=192.168.3.141 and protocol1=SSH-2.0-OpenSSH_5.3 for all events
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: Protocol major versions differ for (\S+): (\S+) vs\. (\S+)$/) {

    ++$data->{"protocol_diff"}->{"host"}->{$1};
    ++$data->{"protocol_diff"}->{"protocol1"}->{$2};
    ++$data->{"protocol_diff"}->{"protocol2"}->{$3};

  }

  # template: sshd[<*>]: Address <*> maps to <*>, but this does not map back to the address - POSSIBLE BREAK-IN ATTEMPT!
  # openchat: no (the template 'sshd[<*>]: Address <*> maps to <*> but this does not map back to the address - POSSIBLE BREAK-IN ATTEMPT!' is very close, but the comma after the hostname is not detected)
  # drain: yes (<*> Address 192.168.2.167 maps to ws112.example.com, but this does not map back to the address - POSSIBLE BREAK-IN ATTEMPT!), note that ip=192.168.2.167 and host=ws112.example.com for all events
  # mistral: no
  # wizardlm2: yes (sshd[<*>]: Address <*> maps to ws112.example.com, but this does not map back to the address - POSSIBLE BREAK-IN ATTEMPT!), note that host=ws112.example.com for all events

  elsif (/sshd\[\d+\]: Address (\S+) maps to (\S+), but this does not map back to the address - POSSIBLE BREAK-IN ATTEMPT!$/) {

    ++$data->{"mapping_issue"}->{"ip"}->{$1};
    ++$data->{"mapping_issue"}->{"host"}->{$2};

  }

  # template: sshd[<*>]: error: <*>
  # openchat: no (the template 'sshd[<*>]: error: Received disconnect from <*> port <*>' is close, but does not cover events without the substring "port")
  # drain: no
  # mistral: no
  # wizardlm2: no

  elsif (/sshd\[\d+\]: error: (.+)$/) {

    ++$data->{"ssh_error"}->{"message"}->{$1};

  }

  # template: sshd[<*>]: dispatch_protocol_error: type <*> seq <*>
  # openchat: yes (sshd[<*>]: dispatch_protocol_error: type <*> seq <*>)
  # drain: yes (<*> dispatch_protocol_error: type <*> seq <*>)
  # mistral: no (two more specific templates are detected)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: dispatch_protocol_error: type (\d+) seq (\d+)$/) {

    ++$data->{"ssh_dispatch_protocol_error"}->{"type"}->{$1};
    ++$data->{"ssh_dispatch_protocol_error"}->{"seq"}->{$2};

  }

  # template: sshd[<*>]: fatal: <*>
  # openchat: no (three separate templates detected)
  # drain: no (three separate templates detected)
  # mistral: no (two separate templates detected)
  # wizardlm2: no

  elsif (/sshd\[\d+\]: fatal: (.+)$/) {

    ++$data->{"ssh_fatal"}->{"message"}->{$1};

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

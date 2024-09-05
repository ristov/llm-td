#!/usr/bin/perl -w
#
# LLM-TD 0.01 - llm-td.pl
# Copyright (C) 2024 Risto Vaarandi
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#


use strict;
use Getopt::Long;

use vars qw(
  $batch
  $filter
  $help
  $logfile
  $model
  $parser
  %patterns
  $prompt
  $regexp
  $script
  $token
  $usage
);


$usage = qq!Usage: $0 [options] 

Options:

  --batch=N
  Set the batch size to N. Default is value for N is 10.

  --logfile=F
  Detect templates from logfile F.

  --model=M
  Use large language model M for template detection.

  --regexp=R
  use regular expression R for parsing lines in logfile F.
  Note that R must set the match variable \$+{line} to the logfile line
  part where templates are detected from. Also, R must set the match 
  variable \$+{program} to the program name in the logfile line.
  Default of R is the following regular expression:
  ^(?:[A-Z][a-z]{2} [ \\d]\\d (\\d\\d:){2}\\d\\d|\\d{4}-\\d\\d-\\d\\dT(\\d\\d:){2}\\d\\d(?:\\.\\d+)?(?:Z|[+-]\\d\\d(?::\\d\\d)?)) \\S+ (?<line>(?<program>\\S+?)(?:\\[\\d+\\])?:.*)

  --script=S
  use script S for executing the query to large language model M.
  Note that model name M is passed to S as its first command line argument,
  and the prompt for querying M is provided to S through standard input.
  The script S must print the response from LLM to standard output.

  --token=T
  use T as a token for denoting the wildcard in detected templates.
  Default value for T is <*>.

  --help
  Print this help.

Example command line:

  ./llm-td.pl --model=openchat --logfile=sshd.log --script=./llm-query.sh

!;


sub set_prompt {

$prompt = qq!Consider the following example log file:

sshd[5100]: Accepted password for robert from 10.1.7.13 port 49190 ssh2
sshd[5100]: pam_unix(sshd:session): session opened for user robert by (uid=0)
sshd[5106]: Received disconnect from 10.1.7.13 port 49190:11: Shutdown
sshd[5100]: pam_unix(sshd:session): session closed for user robert
sshd[8597]: Accepted publickey for john from 192.168.5.2 port 54060 ssh2
sshd[8597]: pam_unix(sshd:session): session opened for user john by (uid=0)
sshd[8607]: Received disconnect from 192.168.5.2 port 54060:11: disconnected by user
sshd[8597]: pam_unix(sshd:session): session closed for user john

From this example log file, the following log message templates can be detected:

sshd[$token]: Accepted $token for $token from $token port $token ssh2
sshd[$token]: pam_unix(sshd:session): session opened for user $token by (uid=$token)
sshd[$token]: Received disconnect from $token port $token:$token: $token
sshd[$token]: pam_unix(sshd:session): session closed for user $token

Considering the above example, find log message templates from the following file:

!;

}


sub get_options {

  $batch = 10;
  $token = '<*>';
  $help = 0;

  $regexp = '^(?:[A-Z][a-z]{2} [ \d]\d (\d\d:){2}\d\d|\d{4}-\d\d-\d\dT(\d\d:){2}\d\d(?:\.\d+)?(?:Z|[+-]\d\d(?::\d\d)?)) \S+ (?<line>(?<program>\S+?)(?:\[\d+\])?:.*)'; 

  GetOptions("batch=i" => \$batch,
             "logfile=s" => \$logfile,
             "model=s" => \$model,
             "regexp=s" => \$regexp,
             "script=s" => \$script,
             "token=s" => \$token,
             "help|?" => \$help
  );

  if ($help) { 
    print $usage; 
    exit(0); 
  }

  if (!defined($model)) {
    print STDERR "Provide model with the --model option\n";
    exit(1);
  }

  if (!defined($logfile)) {
    print STDERR "Provide logfile with the --logfile option\n";
    exit(1);
  }

  if (!defined($script)) {
    print STDERR "Provide script with the --script option\n";
    exit(1);
  }

  $parser = eval { qr/$regexp/ };

  if ($@) {
    print STDERR 
      "Invalid regular expression provided with the --regexp option: $@\n";
    exit(1);
  }

}


sub derive_regexp {

  my($line) = $_[0];
  my($part, $sep, $remainder, $regexp, $quoted_token);


  $quoted_token = quotemeta($token);

  $regexp = "";
  
  $remainder = $line;

  while ($line =~ /\G(.*?)(\s+|$quoted_token)/g) {

    $part = $1;
    $sep = $2;
    $remainder = $';

    if ($part ne "") { $regexp .= quotemeta($part); }

    if ($sep eq $token) { $regexp .= '.+?'; } else { $regexp .= '\s+'; }

  }

  if ($remainder ne "") { $regexp .= quotemeta($remainder); }
  
  $regexp .= '\s*$';

  return qr/$regexp/;
}


sub process_file_chunk {

  my($inputfile) = $_[0];
  my(@output, %patternbuf);
  my($line, $pattern);


  @output = `cat $inputfile | $script $model`;

  chomp @output;

  foreach $line (@output) {

    if ($line =~ $filter) {

      $pattern = $+{pattern};

      if (!exists($patterns{$pattern})) { 
        $patternbuf{$pattern} = derive_regexp($pattern);
      }
    }

  }

  return \%patternbuf;
}


sub validate_patterns {

  my($buffer, $temp_patterns) = @_;
  my($line, $pattern, $regexp);


  while (($pattern, $regexp) = each %{$temp_patterns}) {

    for $line (@{$buffer}) {

      if ($line =~ $regexp) { 

        $patterns{$pattern} = { "Regexp" => $regexp, 
                                "Line" => $line,
                                "Matches" => 0 };
        last;
      }
    }

    if (!exists($patterns{$pattern})) {
      print STDERR "Dropping pattern '$pattern' which does not match any line\n";
    }
  }
}


sub prune_patterns {

  my(@patlist, %prune);
  my($i, $j, $pattern, $pattern2, $regexp, $line);


  @patlist = keys %patterns;

  for ($i = 0; $i < scalar(@patlist); ++$i) {

    $pattern = $patlist[$i];
    $regexp = $patterns{$pattern}->{"Regexp"};
    $line = $patterns{$pattern}->{"Line"};

    for ($j = 0; $j < $i; ++$j) {

      $pattern2 = $patlist[$j];

      if ($patterns{$pattern2}->{"Line"} =~ $regexp &&
          $line !~ $patterns{$pattern2}->{"Regexp"}) {

        print STDERR "Pruning pattern '$pattern2' which is more specific than pattern '$pattern'\n";

        $prune{$pattern2} = 1;
      }

    }

  }

  foreach $pattern (@patlist) {
    if (exists($prune{$pattern})) { delete $patterns{$pattern}; }
  }
}


sub build_llm_output_filter {

  my($ref) = $_[0];
  my(@programs, $regexp, $prog_regexp);
  

  @programs = map { quotemeta($_) } keys %{$ref};

  $prog_regexp = '(?:' . join("|", @programs) . ')';

  $regexp = '^\s*(?<pattern>' .  $prog_regexp . '.+)';
 
  return qr/$regexp/;

}


sub process_batch {

  my($buffer) = $_[0];
  my($tempfile, $tempfh, $line, $temp_patterns);


  $tempfile = "/tmp/log-mining.$$";

  if (!open($tempfh, ">$tempfile")) {
    print STDERR "Can't open $tempfile ($!)\n";
    exit(1);
  }

  print $tempfh $prompt;

  foreach $line (@{$buffer}) { print $tempfh $line, "\n"; }

  close($tempfh);

  $temp_patterns = process_file_chunk($tempfile);

  validate_patterns($buffer, $temp_patterns);

  prune_patterns();

  unlink($tempfile);

}


sub detect_patterns {

  my($fh, $line, $program, $pattern);
  my($i, $match, $number, @buffer, %programs);


  $i = 0;

  if (!open($fh, $logfile)) {
    print STDERR "Can't open $logfile ($!)\n";
    exit(1);
  }

  while (<$fh>) {

    ++$i;

    if ($i % 10 == 0) {
      $number = scalar(keys %patterns);
      print STDERR "$i lines processed, $number patterns detected\n";
    }

    if ($_ !~ $parser) { next; }

    $program = $+{program};
    $line = $+{line};

    if (!exists($programs{$program})) {

      $programs{$program} = 1;
      $filter = build_llm_output_filter(\%programs);

      print STDERR "Updating LLM output filter: $filter\n";
    }

    $match = 0;

    foreach $pattern (keys %patterns) {

      if ($line =~ $patterns{$pattern}->{"Regexp"}) { 
        $match = 1;
        last;
      }
    }

    if ($match) { next; }

    push @buffer, $line;

    if (scalar(@buffer) == $batch) {

      process_batch(\@buffer);

      @buffer = ();
    }
  
  }

  close($fh);

  if (scalar(@buffer) > 0)  { process_batch(\@buffer); }

}


sub output_patterns {

  my($fh, $unprocessed, $match, $pattern, $i);
  my(%matches, @keys);


  if (!open($fh, $logfile)) {
    print STDERR "Can't open $logfile ($!)\n";
    exit(1);
  }

  $unprocessed = 0;

  print "Unprocessed lines:\n\n";

  while (<$fh>) {

    $match = 0;
    %matches = ();

    foreach $pattern (keys %patterns) {

      if ($_ =~ $patterns{$pattern}->{"Regexp"}) { 

        ++$patterns{$pattern}->{"Matches"};

        $matches{$pattern} = 1;

        $match = 1;
      }
    }

    if ($match) {

      @keys = keys %matches;

      if (scalar(@keys) == 1) { $patterns{$keys[0]}->{"Unique"} = 1; }

    } else { 

      print $_;

      ++$unprocessed;

    }
  }

  print "\nTotal number of unprocessed lines: $unprocessed\n\n";

  close($fh);

  print "Detected patterns:\n\n";

  $i = 0;

  foreach $pattern (keys %patterns) {

    print $pattern, "\n";
    print $patterns{$pattern}->{"Regexp"}, "\n";
    print $patterns{$pattern}->{"Matches"}, " matches\n";

    if (!exists($patterns{$pattern}->{"Unique"})) {
      print "All lines matching this pattern are covered by other patterns\n";
    }

    print "\n";

    ++$i;
  }

  print "Total number of detected patterns: $i\n";

}

##################################################

get_options();

set_prompt();

print STDERR "Using the following prompt:\n\n$prompt\n";

detect_patterns();

output_patterns();


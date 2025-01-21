#!/usr/bin/perl -w
#
# LLM-TD 0.02 - llm-td.pl
# Copyright (C) 2024-2025 Risto Vaarandi
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
use Time::HiRes qw(gettimeofday);

use vars qw(
  $batch
  $cache_hits
  $debug
  $filter
  $help
  $llm_query_count
  $llm_query_time
  $logfile
  $model
  $parser
  %patterns
  $pat_dropped
  $pat_pruned
  $pat_valid
  $prompt
  $regexp
  $script
  $start_time
  $token
  $total_lines
  $total_time
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
  Note that the program name must be a prefix of \$+{line}, and program
  names are used for recognizing templates in LLM responses.
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

  --debug
  increase logging verbosity

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


sub log_msg {

  my($message) = join("", @_);
  my($time, $time2);

  $time = sprintf("%.3f", gettimeofday() - $start_time);
  $time2 = scalar(localtime());

  print STDERR "$time ($time2) $message\n";

}


sub get_options {

  $batch = 10;
  $token = '<*>';
  $help = 0;
  $debug = 0;

  $regexp = '^(?:[A-Z][a-z]{2} [ \d]\d (\d\d:){2}\d\d|\d{4}-\d\d-\d\dT(\d\d:){2}\d\d(?:\.\d+)?(?:Z|[+-]\d\d(?::\d\d)?)) \S+ (?<line>(?<program>\S+?)(?:\[\d+\])?:.*)'; 

  GetOptions("batch=i" => \$batch,
             "logfile=s" => \$logfile,
             "model=s" => \$model,
             "regexp=s" => \$regexp,
             "script=s" => \$script,
             "token=s" => \$token,
             "debug" => \$debug,
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
  my($line, $pattern, $t, $diff, $time);


  $t = gettimeofday();

  @output = `cat $inputfile | $script $model`;

  $diff = gettimeofday() - $t;

  if ($debug) {

    $time = sprintf("%.3f", $diff);
    log_msg("LLM query time $time seconds");
  }

  $llm_query_time += $diff;
  ++$llm_query_count;

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
  my($valid, $dropped);

  $valid = 0;
  $dropped = 0;

  while (($pattern, $regexp) = each %{$temp_patterns}) {

    for $line (@{$buffer}) {

      if ($line =~ $regexp) { 

        $patterns{$pattern} = { "Regexp" => $regexp, 
                                "Line" => $line,
                                "Matches" => 0,
                                "New" => 1 };

        ++$valid;

        last;
      }
    }

    if (!exists($patterns{$pattern})) {
      log_msg("Dropping pattern '$pattern' which does not match any line");
      ++$dropped;
    }
  }

  return ($valid, $dropped);
}


sub prune_patterns {

  my(@patlist, %prune);
  my($i, $j, $pattern, $pattern2, $regexp, $line, $pruned);


  $pruned = 0;

  @patlist = keys %patterns;

  for ($i = 0; $i < scalar(@patlist); ++$i) {

    $pattern = $patlist[$i];
    $regexp = $patterns{$pattern}->{"Regexp"};
    $line = $patterns{$pattern}->{"Line"};

    for ($j = 0; $j < scalar(@patlist); ++$j) {

      if ($i == $j) { next; }

      $pattern2 = $patlist[$j];

      if (!exists($patterns{$pattern}->{"New"}) &&
          !exists($patterns{$pattern2}->{"New"})) {

        next;
      }

      if ($patterns{$pattern2}->{"Line"} =~ $regexp &&
          $line !~ $patterns{$pattern2}->{"Regexp"}) {

        log_msg("Pruning pattern '$pattern2' which is more specific than pattern '$pattern'");

        $prune{$pattern2} = 1;
      }

    }

  }

  foreach $pattern (@patlist) {

    if (exists($patterns{$pattern}->{"New"})) {
      delete $patterns{$pattern}->{"New"};
    }

    if (exists($prune{$pattern})) { 
      delete $patterns{$pattern}; 
      ++$pruned;
    }
  }

  return $pruned;
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
  my($valid, $dropped, $pruned);


  $tempfile = "/tmp/log-mining.$$";

  if (!open($tempfh, ">$tempfile")) {
    print STDERR "Can't open $tempfile ($!)\n";
    exit(1);
  }

  print $tempfh $prompt;

  foreach $line (@{$buffer}) { print $tempfh $line, "\n"; }

  close($tempfh);

  $temp_patterns = process_file_chunk($tempfile);

  ($valid, $dropped) = validate_patterns($buffer, $temp_patterns);

  $pruned = prune_patterns();

  if ($debug) {

    log_msg("LLM query results: valid=", $valid, 
            " dropped=", $dropped, " pruned=", $pruned);
  }

  $pat_valid += $valid;
  $pat_dropped += $dropped;
  $pat_pruned += $pruned;

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
      log_msg("$i lines processed, $number patterns detected");
    }

    if ($_ !~ $parser) { next; }

    $program = $+{program};
    $line = $+{line};

    if (!exists($programs{$program})) {

      $programs{$program} = 1;
      $filter = build_llm_output_filter(\%programs);

      log_msg("Updating LLM output filter: $filter");
    }

    $match = 0;

    foreach $pattern (keys %patterns) {

      if ($line =~ $patterns{$pattern}->{"Regexp"}) { 
        $match = 1;
        last;
      }
    }

    if ($match) { 

      ++$cache_hits;
      next; 
    }

    push @buffer, $line;

    if (scalar(@buffer) == $batch) {

      process_batch(\@buffer);

      @buffer = ();
    }
  
  }

  $total_lines = $i;

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

  foreach $pattern (sort keys %patterns) {

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

$start_time = gettimeofday();

$llm_query_time = 0;
$llm_query_count = 0;

$pat_valid = 0;
$pat_dropped = 0;
$pat_pruned = 0;

$cache_hits = 0;
$total_lines = 0;


get_options();

set_prompt();

log_msg("Using the following prompt:\n\n$prompt\n");

detect_patterns();

output_patterns();


$total_time = gettimeofday() - $start_time;

log_msg("Total runtime ", sprintf("%.3f", $total_time), " seconds");

log_msg("Total number of cache hits $cache_hits");
log_msg("Total number of processed lines $total_lines");
log_msg("Total number of lines processed by LLM ", $total_lines - $cache_hits);

log_msg("Total LLM query time ", sprintf("%.3f", $llm_query_time), " seconds");
log_msg("Total LLM query count $llm_query_count");

log_msg("Total number of valid patterns from LLM queries $pat_valid");
log_msg("Total number of invalid patterns from LLM queries $pat_dropped");
log_msg("Total number of pruned patterns from LLM queries $pat_pruned");


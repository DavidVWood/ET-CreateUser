#!/usr/bin/perl
use strict;
use warnings;

######################################################################
# file: ET-CreateUsers.pl
# purpose: read user information from CSV file (first argument) and 
#          push data to ET via the GEMS user/post API
######################################################################

use LWP::UserAgent ();
use Data::Dumper;

sub logMessage($);
sub dieMessage($);

# verify/open CSV file
my $file = $ARGV[0] or dieMessage "Need to get CSV file on the command line\n";
open(my $data, '<', $file) or dieMessage "Could not open '$file' $!\n";

# create/open LOG file
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $ymd = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
open LOG, ">>ET-CreateUsers_$ymd.log" or die $!; # create if not there
 
# process lines to ET via GEMS user/post API
while (my $line = <$data>) {
  chomp $line;

  # skip first line
  next if ($line =~ /notificationEmailAddress/);
  
  my ($emailAddress,
      $notificationEmailAddress,
      $username,
      $password,
      $name,
      $defaultBusinessUnitCode,
      $timeZone,
      $locale,
      $businessUnitCodeArray,
      $roleCodeArray) = split "," , $line;
  
  # build JSON data
  my $json;
  $json  = "{\n";
  $json .= "\t\"emailAddress\":\"$emailAddress\",\n";
  $json .= "\t\"notificationEmailAddress\":\"$notificationEmailAddress\",\n";
  $json .= "\t\"username\":\"$username\",\n";
  $json .= "\t\"password\":\"$password\",\n";
  $json .= "\t\"name\":\"$name\",\n";
  $json .= "\t\"defaultBusinessUnitCode\":\"$defaultBusinessUnitCode\",\n";
  $json .= "\t\"timeZone\":$timeZone,\n";
  $json .= "\t\"locale\":\"$locale\",\n";

  $json .= "\t\"businessUnits\":[\n";
  my $delimiter = "|";
  my @BUs = split /\Q$delimiter/, $businessUnitCodeArray;
  foreach my $buc (@BUs)
  {
    $buc =~ s/(^\s+|\s+$)//g;
    $json .= ",\n" if ($json =~ /{"businessUnitCode":/);
    $json .= "\t\t{\"businessUnitCode\":\"$buc\"}";
  }
  $json .= "\n\t],\n";

  $json .= "\t\"roles\":[\n";
  my @Rs = split /\Q$delimiter/, $roleCodeArray;
  foreach my $rc (@Rs)
  {
    $rc  =~ s/(^\s+|\s+$)//g;
    $json .= ",\n" if ($json =~ /{"roleCode":/);
    $json .= "\t\t{\"roleCode\":\"$rc\"}";
  }
  $json .= "\n\t]\n";
  $json .= "}\n";
  
  logMessage "POST: $json\n";
  
  # post JSON to URL
  my $uri = 'http://relaunch-web-dev.usatoday.com:2103/EmailApiService/EmailApiService.svc/user';
  my $req = HTTP::Request->new( 'POST', $uri );
  
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json );
  
  my $lwp = LWP::UserAgent->new;
  my $response = $lwp->request( $req );
  
  if ($response->is_success) {
    logMessage "RESPONSE: " . $response->decoded_content . "\n";
  }
  else {
    logMessage $response->status_line;
    close LOG;
    die "";
  }
}

close LOG;

exit(0);

######################################################################
######################################################################
######################################################################
######################################################################

sub logMessage ($) {
  my ($msg) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $ts = sprintf("%02d/%02d/%04d-%02d:%02d.%02d",$mon+1,$mday,$year+1900,$hour,$min,$sec);

  print LOG $ts."\t".$msg;
  print $msg;
}

sub dieMessage ($) {
  my ($msg) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $ts = sprintf("%02d/%02d/%04d-%02d:%02d.%02d",$mon+1,$mday,$year+1900,$hour,$min,$sec);

  print LOG $ts."\t".$msg;
  die $msg;
}

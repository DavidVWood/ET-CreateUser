#!/usr/bin/perl
use strict;
use warnings;

use LWP::UserAgent ();

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

open(my $data, '<', $file) or die "Could not open '$file' $!\n";

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
  
  #print "$json\n";
  
  # post JSON to URL
  my $uri = 'http://relaunch-web-dev.usatoday.com:2103/EmailApiService/EmailApiService.svc/user';
  my $req = HTTP::Request->new( 'POST', $uri );
  
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json );
  
  my $lwp = LWP::UserAgent->new;
  $lwp->request( $req );
}

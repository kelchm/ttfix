#!/usr/bin/perl

# ttfix.pl
# A very simple TimThumb replacement script
# Matthew Kelch
# v0.3

use File::Copy;
use File::Find;
use LWP::UserAgent;

$vps_mode = 1;	# set to 0 for Hybrid, 1 for VPS host node
$tt_ver = '2.8.10';
$tt_url='http://timthumb.googlecode.com/svn/trunk/timthumb.php';
$base_dir = "/home/";
$count = 0;

&download_timthumb;

if($vps_mode == 1)
{
	# find all relevant directories
	@vzhomes = glob "/vz/private/*/home/";
	find(\&find_timthumb, @vzhomes);
}
else 
{
	find(\&find_timthumb, $base_dir);
}

print "Completed.  $count files were replaced.\n";

sub download_timthumb
{
	my $ua = new LWP::UserAgent;
	$ua->timeout(120);
	my $request = new HTTP::Request('GET', $tt_url);
	my $response = $ua->request($request);
	$good_timthumb = $response->content();
	
	# This is a pretty useless check.
	if(length($good_timthumb) < 40000)
	{
		 die "Downloaded TimThumb script looks invalid.";
	}	
}

sub find_timthumb
{
    # we are only concerned with timthumb.php or thumb.php
    -f $_ && (/timthumb.php$/i|/thumb.php$/i) or return;	
	open($fh, $File::Find::name);
	
	# all known examples of timthumb contain 'timthumb' somewhere in the file
	if(grep(timthumb,$fh))
	{
		&check_version;
	}
	
	close $fh;
}

sub check_version
{
	$replace = 0;
	$ver = undef;
	
	foreach $line (<$fh>)
	{
		# look for the version number with a regular expression
		$line =~ m/define \('VERSION', '([0-9\.]+)'\);/;
		
		# check to see if the version 
		if($1 ne '' && $1 lt $tt_ver)
		{
			$replace = 1;
			$ver = $1;
			last;	# eascape the loop (for efficiency)
		}
	}
	
	# this catches any old versions which have no version number defined
	if($replace eq 0 && $1 ne '')
	{
		$replace = 1;
	}
	
	if($replace eq 1)
	{
		&replace;
	}
}

sub replace
{
	
	my $copy = 'timthumb.disabled';
	
	print "Replacing $File::Find::name - Version: $ver \n";
	
	copy($File::Find::name, $copy) or die "File cannot be copied.";
				
	close $fh;							# close the read only fh
	open($fh, ">", $File::Find::name); 	# open in write mode
	truncate($File::Find::name, 0 ); 	# empty the original
	print $fh $good_timthumb;			# write the downloaded timthumb
	
	$count++;
}
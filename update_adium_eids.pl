#!/usr/bin/env perl
use strict;
use warnings;
use LWP::Simple;
use XML::XPath;

my $contact_names = `echo 'tell application "Adium" to return display name of every contact of every account of service "Jabber"' | osascript`;
chomp $contact_names;
my @contact_names = split(/,\ ?/,$contact_names);

for my $id (@contact_names) {
    if ($id =~ /^[a-z][a-z0-9]+$/) {
        print "Processing eID $id...\n";
        my $eid_xml = get('http://search.k-state.edu/People/eid/' . $id);
        my $xp = XML::XPath->new( xml => $eid_xml );
        
        my ($first, $last);
        $first = $xp->getNodeText('/results/result/pref/fn')->value();
        $first = $xp->getNodeText('/results/result/fn')->value() unless $first;
        $last = $xp->getNodeText('/results/result/pref/ln')->value();
        $last = $xp->getNodeText('/results/result/ln')->value() unless $last;
        if ($first eq '' and $last eq '') {
            print "Didn't find any names, aborting.\n";
            next;
        }
        print "$id = $first $last\n";
        
        my $script = q{tell application "Adium" to set the display name of every contact }
                . qq{whose display name is "$id" to "$first $last" };
        print $script, "\n";
        open my $fh, "|-", "osascript";
        print $fh "$script\n";
        close $fh
    }
}
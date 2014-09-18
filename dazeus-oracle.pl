#!/usr/bin/perl
# MOracle is written by and copyright (C) 2007 Bart Schuurmans
# aka Minnozz <bart.schuurmans@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use DaZeus;
use strict;
use warnings;

my ($socket) = @ARGV;

if (!$socket) {
	warn "Usage: $0 socket\n";
	exit 1;
}

print "Now connecting to $socket...";
my $dazeus = DaZeus->connect($socket);
print " connected!\n";

$dazeus->subscribe_command("oracle" => sub {
	my ($self, $network, $sender, $channel, $command, $arg) = @_;
	if (!defined($arg) || $arg eq "") {
		reply("You'll have to give the oracle something to work with, " . $sender . ".", $network, $sender, $channel);
	} else {
		reply("That is " . oracle($arg) . "% true.", $network, $sender, $channel);
	}
});

while($dazeus->handleEvents()) {}

sub reply {
	my ($response, $network, $sender, $channel) = @_;

	if ($channel eq $dazeus->getNick($network)) {
		$dazeus->message($network, $sender, $response);
	} else {
		$dazeus->message($network, $channel, $response);
	}
}

sub oracle {
	my $string = lc(shift @_);
	$string =~ s/[^a-zA-Z]//g;
	my @letters = split (//, $string);
	my @numbers;
	while (@letters) {
		my $curlet = shift (@letters);
		my $amount = $string =~ s/$curlet//g;
		push (@numbers, $amount);
	}
	@numbers = splitnum (@numbers);
	while (@numbers > 2) {	# Range from 10% ...
		my @newnum;
		while (@numbers) {
			my $first = shift @numbers;
			my $last;
			if (@numbers) {
				$last = pop @numbers;
			} else {
				$last = 0;
			}
			my $number =  $first + $last;
			push (@newnum, $number);
		}
		@numbers = splitnum (@newnum);
		last if (join ('', @numbers) == 100);	# ... to 100%
	}
	return join ('', @numbers);
}

sub splitnum {
	# Make sure that each array item contains only one digit. If not, split into two digits.
	my $temp;
	for (@_) {
		$temp .= $_;
	}
	my @return = split (//, $temp);
	return @return;
}

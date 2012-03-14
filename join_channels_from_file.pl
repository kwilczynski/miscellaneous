use strict;
use warnings;

use Irssi;

sub join_channels_from_file {
    my ($argument, $server) = @_;

    my $chatnet = $server->{'chatnet'};

    if ($argument) {
        $argument =~ s/^~(?=\/|$)/$ENV{HOME} ? "$ENV{HOME}" : "$ENV{PWD}"/e;

        eval {
            open(FILE, '<' . $argument);

            while (<FILE>)
            {
                s/^$//;
                s/\n|\n\r//;

                Irssi::print("Joining channel: " . $_);

                Irssi::Server::channels_join($server, $_, 0);

                sleep 0.1;
            }

          close(FILE);
        };

        if ($@) {
          Irssi::print("Unable to load channels from given file");
        }

    } else {
      Irssi::print("Please specify file containing list of channels");
    }
}

Irssi::command_bind('join_channels_from_file', 'join_channels_from_file');

package CopyRename {
    use strict;
    use warnings;
    use feature 'say';
    use File::Copy 'copy';
    use File::Copy::Recursive qw/fmove rmove rcopy/;

    my $dir  = '.';
    my $tree = '';
    my $fmt = '';
    my $message_confirmation;
    my $message_choice;

    sub init {
        my $command = shift;

        $message_choice = "Put the words before & after.(or [ls/q/quit])";
        if ($command eq 'rcopy') {
            $message_confirmation = "Copy it OK? [y/N]\n";
        }
        elsif ($command eq 'rname') {
            $message_confirmation = "Move it OK? [y/N]\n";
        }

        print "f/d/a/q?\n>> ";
        chomp(my $init = <STDIN>);

        if ($init eq 'f') {
            $fmt = 'file';
        }
        elsif ($init eq 'd') {
            $fmt = 'dir';
        }
        elsif ($init eq 'a') {
            $fmt = 'all';
        }
        elsif ($init eq 'q') {
            say "Exit.";
            exit;
        }
        else {
            init($command);
        }

        result($fmt);
        main($command);
    }

    sub result {
        my $fmt = shift;

        my (@file, @dir) = ();
        my $last_dir = '';

        opendir(my $iter, $dir) or die;
        for (readdir $iter) {
            next if ($_ =~ /\A\./);
            if (-f $dir . '/' . $_) {
                push @file, "\tfile: $_\n";
            }
            elsif (-d $dir . '/' . $_) {
                push @dir, "\tdir: $_/\n";
                $last_dir = $_;
            }
        }
        closedir $iter;

        say 'ls:';
        if ($fmt eq 'dir') {
            print @dir;
        }
        elsif ($fmt eq 'file') {
            print @file;
        }
        else {
            print @dir;
            print @file;
        }
        if ($tree =~ /\A([^\/]+)\/([^\/]+)/) {
            say "\t---";
            my @tree = `tree $1`;
            for (@tree) {
                print "\t$_";
            }
            $tree = '';
        }
        print "\n";
    }

    sub main {
        my $command = shift;

        say $message_choice;
        chomp(my $get = <STDIN>);

        unless ($get =~ /\A(q|e|quit|exit)\z/) {
            chomp $get;
            my ($before, $after);
            my @after  = ();
            my @match  = ();
            my @source = ();
            my $source = '';

            if ($get =~ /\A(\S+)(( +(\S+))+)/) {
                $before = $1;
                $after  = $2;
                @after  = split / /, $after;

                opendir(my $iter, $dir) or die;
                for $source (readdir $iter) {
                    next if ($source =~ /^\./);
                    if ($fmt eq 'file') {
                        next unless (-f $dir . '/' . $source);
                    }
                    elsif ($fmt eq 'dir') {
                        next unless (-d $dir . '/' . $source);
                    }
                    elsif ($fmt eq 'all') {
                        next unless (-e $dir . '/' . $source);
                    }
                    if ($source =~ /$before/) {
                        $source = $source . '/' if (-d $source);
                        push @source, $source;
                        for (@after) {
                            next if ($_ eq '');
                            my $new = $source;
                            $new =~ s/$before/$_/;
                            if (-e $dir . '/' . $new) {
                                say "$new is already exist.";
                                next;
                            }
                            $new = $new . '/' if (-d $new);
                            push @match, $new;
                        }
                    }
                }
                closedir $iter;

                if (scalar(@match) > 0) {
                    say "\nfrom:";
                    for (@source) {
                        say "\t$_";
                    }
                    say "to:";
                    $tree = '';
                    for (@match) {
                        $tree = $_;
                        say "\t$_";
                    }
                    say "\n$message_confirmation";
                    my $source = '';
                    chomp(my $result = <STDIN>);
                    if ($result =~ /\A(y|yes)\z/) {
                        opendir(my $iter, $dir) or die;
                        for $source (readdir $iter) {
                            next if ($source =~ /^\./);
                            if ($source =~ /$before/) {
                                for (@after) {
                                    next if ($_ eq '');
                                    my $new = $source;
                                    $new =~ s/$before/$_/;
                                    if ($fmt eq 'file') {
                                        next unless (-f $source);
                                        if ($command eq 'rcopy') {
                                            copy($source, $new) or die $!;
                                        }
                                        elsif ($command eq 'rname') {
                                            fmove($source, $new) or die $!;
                                        }
                                    }
                                    else {
                                        if ($fmt eq 'dir') {
                                            next unless (-d $source);
                                        }
                                        if ($command eq 'rcopy') {
                                            rcopy($source, $new) or die $!;
                                        }
                                        elsif ($command eq 'rname') {
                                            rmove($source, $new) or die $!;
                                        }
                                    }
                                }
                            }
                        }
                        closedir $iter;
                    }
                    else {
                        say "Nothing changes.\n";
                    }
                }
                else {
                    say "Not matched: $before\n";
                }
            }
            else {
                say "Incorrect command.";
            }
            result($fmt);
            init($command);
        }
        else {
            say "Exit.";
        }
    }
}

1;
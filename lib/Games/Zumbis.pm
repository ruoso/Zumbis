package Games::Zumbis;
use strict;
use warnings;

use File::ShareDir ();
use Path::Class    ();
use FindBin        ();

our $VERSION = 0.01;
my $sharedir;

sub sharedir {
    return $sharedir if $sharedir;

    my $root = Path::Class::Dir->new($FindBin::Bin);
warn "procurando $root";
    # desenvolvimento
    if ( -f $root->file('dist.ini') ) {
        $sharedir = $root->subdir('share');
    }
    # instalado
    else {
        $sharedir = Path::Class::Dir->new( File::ShareDir::dist_dir('Games-Zumbis') );
    }

    return $sharedir;
}

'zombies!!';

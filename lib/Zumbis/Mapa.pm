use XML::Compile::Schema;
use XML::Compile::Util qw(pack_type);
use constant MAP_NS => 'http://perl.org.br/games/zumbis';
my $map_schema = XML::Compile::Schema->new('mapa.xsd');
my $map_reader = $map_schema->compile(READER => pack_type MAP_NS, 'mapa');

use SDL::Image;
use SDL::Video;

use MooseX::Declare;
class Zumbis::Mapa {
    has arquivo => (is => 'ro', isa => 'Str', required => 1);
    has dados => (is => 'ro', isa => 'HashRef' );
    has colisao => (is => 'ro', isa => 'ArrayRef');
    has tileset => (is => 'ro');

    around BUILDARGS(%args) {
        $args{dados} = $map_reader->($args{arquivo});

        # povoa a matrix de colisoes com 0
        $args{colisao} =
          [ map { [ map { 0 } 0..($args{dados}{width}-1) ] } 0..($args{dados}{height}-1) ];

        for my $object (@{$args{dados}{object}}) {
            my ($x,$y) = split /,/, $object->{position};
            $args{colisao}[$x][$y] = 1;
        }

        $args{surface} = SDL::Image::load($args{dados}{tileset});

        return $orig->BUILDARGS(%args);
    }

    method playerstart {
        return split(/,/, $self->dados->{playerstart});
    }

    method playerstart_px {
        my $tilesize = $self->dados->{tilesize};
        return map { $_ * $tilesize } $self->playerstart;
    }

    method width_px {
        return $self->dados->{width} * $self->dados->{tilesize};
    }

    method height_px {
        return $self->dados->{height} * $self->dados->{tilesize};
    }

    method render($surface) {
        my $tilesize = $self->dados->{tilesize};
        my $tileset  = $self->tileset;

        # renderizar o background;
        my $back_rect = SDL::Rect->new((map {$_ * $tilesize } split /,/, $self->dados->{background}),
                                       $tilesize, $tilesize);
        for my $x (0..($self->dados->{width}-1)) {
            for my $y (0..($self->dados->{height}-1)) {
                my $rect = SDL::Rect->new($x*$tilesize, $y*$tilesize,
                                          $tilesize, $tilesize);
                SDL::Video::blit_surface( $tileset, $back_rect,
                                          $surface, $rect );
            }
        }

        # renderizar os objetos;
        for my $object (@{$self->dados->{object}}) {
            my $src_rect = SDL::Rect->new((map { $_ * $tilesize } split /,/, $object->{tile}),
                                          $tilesize, $tilesize);
            my $dst_rect = SDL::Rect->new((map { $_ * $tilesize } split /,/, $object->{position}),
                                          $tilesize, $tilesize);
            SDL::Video::blit_surface( $tileset, $src_rect,
                                      $surface, $dst_rect );
        }

    }
}

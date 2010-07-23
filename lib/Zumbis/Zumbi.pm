package Zumbis::Zumbi;
use Moose;
use MooseX::Method::Signatures;
use SDL::Rect;
use SDL::Image;
use SDL::Video;

use constant SPRITE_IMAGE => 'dados/zumbi.png';
use constant SPRITE_NUM_COLS => 3;
use constant SPRITE_NUM_ROWS => 4;
use constant SPRITE_WIDTH => 32;
use constant SPRITE_HEIGHT => 45;
use constant SPRITE_TPS => 2;

has x => (is => 'rw', isa => 'Int', required => 1);
has y => (is => 'rw', isa => 'Int', required => 1);
has sprite => (is => 'ro', isa => 'SDLx::Sprite::Animated',
               handles => ['sequence']);


around 'BUILDARGS' => sub {
    my ($orig, $self, %args) = @_;

    my $z = SDLx::Sprite::Animated->new
      ( image => SPRITE_IMAGE,
        rect  => SDL::Rect->new(SPRITE_NUM_COLS,
                                SPRITE_NUM_ROWS,
                                SPRITE_WIDTH,
                                SPRITE_HEIGHT),
        ticks_per_frame => SPRITE_TPS,
      );

    $z->set_sequences
      ( parado_esquerda => [ [1, 3] ],
        parado_direita  => [ [1, 1] ],
        parado_cima     => [ [1, 0] ],
        parado_baixo    => [ [1, 2] ],
        esquerda        => [ [0,3], [1,3], [2,3] ],
        direita         => [ [0,1], [1,1], [2,1] ],
        cima            => [ [0,0], [1,0], [2,0] ],
        baixo           => [ [0,2], [1,2], [2,2] ],
      );

    $z->sequence('parado_baixo');
    $z->start();

    return $orig->($self, %args, sprite => $z);
};

method tick($dt, $mapa, $heroi_x, $heroi_y) {
    # TODO
}

method rect {
    return SDL::Rect->new($self->x + 15, $self->y + 35,
                          32,32);
}

method render($surface) {
    $self->sprite->draw_xy( $surface, $self->x, $self->y );
}

__PACKAGE__->meta->make_immutable();

1;

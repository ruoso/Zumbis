package Zumbis::Zumbi;
use Moose;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use Clone 'clone';

use constant SPRITE_IMAGE => 'dados/zumbi.png';
use constant SPRITE_NUM_COLS => 3;
use constant SPRITE_NUM_ROWS => 4;
use constant SPRITE_WIDTH => 32;
use constant SPRITE_HEIGHT => 45;
use constant SPRITE_TPS => 2;

has x => (is => 'rw', required => 1);
has y => (is => 'rw', required => 1);
has sprite => (is => 'ro', isa => 'SDLx::Sprite::Animated',
               handles => ['sequence']);
has tx => (is => 'rw', isa => 'Int');
has ty => (is => 'rw', isa => 'Int');
has vel => (is => 'rw', default => 0.7);
has change_dt => (is => 'rw', default => \&set_new_dt  );
has dt => (is => 'rw', default => 0 );

sub set_new_dt { (500 + rand 10) }

sub BUILDARGS {
    my ($self, %args) = @_;

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

    return { %args, sprite => $z };
};

sub tick {
    my ($self, $dt, $mapa, $heroi_x, $heroi_y) = @_;
    my $tilesize = $mapa->tilesize;

    # muda a direcao do zumbi com o tempo
    $self->dt( $self->dt + $dt );
    if ($self->dt > $self->change_dt) {
        $self->dt(0);
        my @direcoes = qw(cima baixo esquerda direita);
        $self->sprite->sequence($direcoes[int rand @direcoes ]);
    }

    # move o zumbi
    my $sequencia = $self->sprite->sequence;
    my $vel = $self->vel;
    my ($change_x, $change_y) = (0,0);
    if    ($sequencia eq 'esquerda') { $change_x = 0 - $vel * $dt }
    elsif ($sequencia eq 'direita' ) { $change_x = $vel * $dt     }
    elsif ($sequencia eq 'cima'    ) { $change_y = 0 - $vel * $dt }
    elsif ($sequencia eq 'baixo'   ) { $change_y = $vel * $dt     }

    my $tilex = int(($self->x + $change_x + 15) / $tilesize);
    my $tiley = int(($self->y + $change_y + 35) / $tilesize);

    unless ($mapa->colisao->[$tilex][$tiley]) {
        warn $change_x . '/' . $change_y;
        $self->x( $self->x + $change_x);
        $self->y( $self->y + $change_y);
    }

#    my ($h_t_x, $h_t_y, $z_t_x, $z_t_y) = map { int($_ / $tilesize) }
#      $heroi_x, $heroi_y, $self->x, $self->y;
#
#    if (!$self->tx ||
#        !$self->ty ||
#        $z_t_x != $self->tx ||
#        $z_t_y != $self->ty) {
#
#        # acabou de mudar de quadrado... então pode decidir a direção
#        $self->tx($z_t_x);
#        $self->ty($z_t_y);
#
#        # decidir a próxima direção... precisamos fazer uma cópia do
#        # mapa de colisão para fazer o algoritmo de shortest-path do
#        # Dijkstra.
#        
#        
#    }
}

sub rect {
    return SDL::Rect->new($_[0]->x + 15, $_[0]->y + 35,
                          32,32);
}


sub render {
    my ($self, $surface) = @_;
    $self->sprite->draw_xy( $surface, $self->x, $self->y );
}

__PACKAGE__->meta->make_immutable();

1;

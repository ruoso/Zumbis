package Zumbis::Zumbi;
use 5.10.0;
use Moose;
use MooseX::Method::Signatures;
use SDL::Rect;
use SDL::Image;
use SDL::Video;

has x => (is => 'rw', isa => 'Int', required => 1);
has y => (is => 'rw', isa => 'Int', required => 1);
has vel => (is => 'rw', required => 1, default => 3);
has type => (is => 'rw', required => 1);
has collided => (is => 'rw', default => 0);

my $sprites = SDL::Image::load('dados/bullet.png');
my %rects =
  ( rtl => SDL::Rect->new(0, 0, 20, 10),
    ltr => SDL::Rect->new(0, 10, 20, 10),
    btu => SDL::Rect->new(0, 20, 10, 20),
    tpd => SDL::Rect->new(10, 20, 10, 20),
  );

method tick($dt, $mapa) {
    my $tilesize = $mapa->tilesize;

    my ($o_t_x, $o_t_y) = map { int($_ / $tilesize) }
      $self->x, $self->y;

    my ($change_x, $change_y);
    given ($self->type) {
        when 'rtl' { $change_x = 0 - $self->vel * $dt };
        when 'ltr' { $change_x = $self->vel * $dt };
        when 'btu' { $change_y = 0 - $self->vel * $dt };
        when 'tpd' { $change_y = $self->vel * $dt };
    }

    $self->x($self->x + $change_x);
    $self->y($self->y + $change_y);

    my ($tiles_x, $tiles_y) = map { int($_ / $tilesize) }
      ($change_x, $change_y);

    my ($step_x, $step_y) = map { $_ > 0 ? 1 : -1 }
      ($tiles_x, $tiles_y);

    my ($n_t_x, $n_t_y) = ($o_t_x, $o_t_y);
    while ($tiles_x &&
           $n_t_x >= 0 &&
           $n_t_x < $mapa->width) {
        if ($mapa->colisao->[$n_t_x][$n_t_y]) {
            $self->collided(1)
              return;
        }
        $tiles_x -= $step_x;
        $n_t_x += $step_x;
    }
    while ($tiles_y &&
           $n_t_y >= 0 &&
           $n_t_y < $mapa->height) {
        if ($mapa->colisao->[$n_t_x][$n_t_y]) {
            $self->collided(1)
              return;
        }
        $tiles_y -= $step_y;
        $n_t_y += $step_y;
    }
}


method rect {
    return SDL::Rect->new($self->x, $self->y,
                          $rects{$self->type}->w,$rects{$self->type}->h);
}

method render($surface) {
    SDL::Video::blit_surface( $sprites, $rects{$self->type},
                              $surface, $self->rect );
}

1;

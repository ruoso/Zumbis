package Zumbis::TelaGameOver;
use Mouse;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use SDLx::Surface;

has ultimo_frame => (is => 'ro', required => 1);
my $image = SDLx::Surface->new(surface => SDL::Image::load('dados/gameover.png'));

sub BUILDARGS {
    my ($self, %args) = @_;

    my $surface = delete $args{surface}
      or die 'faltou o argumento "surface" com a tela do jogo';

    my $ultimo_frame = SDLx::Surface->new(width => $surface->w,
                                          height => $surface->h);
    my $rect1 =  SDL::Rect->new(0,0,$surface->w,$surface->h);
    my $rect2 =  SDL::Rect->new(0,0,$surface->w,$surface->h);
    $surface->blit($ultimo_frame, $rect1, $rect2);

    $args{ultimo_frame} = $ultimo_frame;
    return \%args;
}

sub render {
    my ($self, $surface) = @_;

    my $rect1 = SDL::Rect->new(0,0,$surface->w,$surface->h);
    my $rect2 = SDL::Rect->new(0,0,$surface->w,$surface->h);
    $self->ultimo_frame->blit($surface, $rect1, $rect2);
    my $srcrect = SDL::Rect->new(0,0,759,408);
    my $dstrect = SDL::Rect->new($surface->w/2-759/2,$surface->h/2-408/2,759,408);
    $image->blit($surface, $srcrect, $dstrect);
}

__PACKAGE__->meta->make_immutable();


1;

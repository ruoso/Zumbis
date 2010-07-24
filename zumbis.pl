#!/usr/bin/perl
use 5.10.0;
use strict;
use warnings;
use SDL;
use SDL::Time;
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use SDLx::Sprite;
use SDLx::Sprite::Animated;
use SDLx::Surface;
use SDLx::Controller;
use Zumbis::Mapa;
use Zumbis::Tiro;
use Zumbis::Zumbi;
use Zumbis::TelaGameOver;
use Zumbis::Audio;

my $mapa = Zumbis::Mapa->new( arquivo => 'mapas/mapa-de-teste-1.xml' );
my $initial_ticks;

my $heroi = SDLx::Sprite::Animated->new(
    image => 'dados/heroi.png',
    rect  => SDL::Rect->new(5,14,32,45),
    ticks_per_frame => 2,
);
my $heroina = SDLx::Sprite::Animated->new(
    image => 'dados/heroina.png',
    rect  => SDL::Rect->new(5,14,32,45),
    ticks_per_frame => 2,
);

my $player = $heroina;

my $telagameover;

my $jogo;
my @zumbis;
my @morrendo;
my @tiros;

my $sequences = {
    parado_esquerda => [ [1, 3] ],
    parado_direita  => [ [1, 1] ],
    parado_cima     => [ [1, 0] ],
    parado_baixo    => [ [1, 2] ],
    esquerda        => [ [0,3], [1,3], [2,3] ],
    direita         => [ [0,1], [1,1], [2,1] ],
    cima            => [ [0,0], [1,0], [2,0] ],
    baixo           => [ [0,2], [1,2], [2,2] ],
};
$heroi->set_sequences(%$sequences);
$heroina->set_sequences(%$sequences);


my ( $player_x, $player_y ) = $mapa->playerstart_px;
#$player->x( $player_x );
#$player->y( $player_y );
my $player_vel = 0.25;
$player->sequence('parado_baixo');
$player->start;

my $tela = SDLx::Surface::display( 
    width => $mapa->width_px,
    height => $mapa->height_px,
    flags => SDL_FULLSCREEN,
);

Zumbis::Audio->init;
Zumbis::Audio->start_music('dados/terrortrack.ogg');

my %pressed;
sub eventos {
    my $e = shift;
    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

    if ( $e->type == SDL_KEYDOWN ) {
        my $tecla = $e->key_sym;
        if ($tecla == SDLK_LEFT) {
            $pressed{esquerda} = 1;
        }
        elsif ($tecla == SDLK_RIGHT) {
            $pressed{direita} = 1;
        }
        elsif ($tecla == SDLK_DOWN) {
            $pressed{baixo} = 1;
        }
        elsif($tecla == SDLK_UP) {
            $pressed{cima} = 1;
        }
        elsif ($tecla == SDLK_SPACE && scalar @tiros < 4) {
            my $type;
            given ($player->sequence) {
                when (/esquerda/) { $type = 'rtl' };
                when (/direita/)  { $type = 'ltr' };
                when (/baixo/)    { $type = 'tpd' };
                when (/cima/)     { $type = 'btu' };
            };
            push @tiros, Zumbis::Tiro->new(x => $player_x, y => $player_y+20,
                                           type => $type);
        }
        if (%pressed) {
            $player->sequence((keys %pressed)[0]);
        }
    }
    elsif ( $e->type == SDL_KEYUP ) {
        my $tecla = $e->key_sym;
        if ($tecla == SDLK_LEFT) {
            delete $pressed{esquerda};
            $player->sequence('parado_esquerda')  unless %pressed;
        }
        elsif ($tecla == SDLK_RIGHT) {
            delete $pressed{direita};
            $player->sequence('parado_direita')  unless %pressed;;
        }
        elsif ($tecla == SDLK_DOWN) {
            delete $pressed{baixo};
            $player->sequence('parado_baixo')  unless %pressed;
        }
        elsif ($tecla == SDLK_UP) {
            delete $pressed{cima};
            $player->sequence('parado_cima') unless %pressed;
        }
        if (%pressed) {
            $player->sequence((keys %pressed)[0]);
        }
    }
    return 1;
}

my $last_zumbi_dt = 0;
sub cria_zumbis {
    my $dt = shift;
    $last_zumbi_dt += $dt;
    if ($last_zumbi_dt > 500 && scalar @zumbis < 5) {
        my ($x, $y) = $mapa->next_spawnpoint_px;
        push @zumbis, Zumbis::Zumbi->new(x => $x, y => $y);
        $last_zumbi_dt = 0;
    }
}

sub move_heroi {
    my $dt = shift;
    my $tilesize = $mapa->dados->{tilesize};

    # verifica se o heroi foi tocado por um zumbi
    # (condicao de derrota)
    for my $z (@zumbis) {
        next if abs($player_x - $z->x) > 25;
        next if abs($player_y - $z->y) > 25;
        init_game_over();
    }

    @tiros = grep { $_->tick($dt, $mapa) } @tiros;

    @zumbis = grep { my $z = $_;
                     !grep {
                         my $t = $_;
                         (!$t->collided &&
                          abs($t->{x} - $z->{x})<32 &&
                          abs($t->{y} - $z->{y})<32)
                           ?($z->sequence($z->sequence=~/morrendo/?'morrendo_'.$z->sequence:()),
                             push(@morrendo,$z),
                             $t->collided(1)
                            ):0;
                     } @tiros
                 } @zumbis;

    my $sequencia = $player->sequence;
    my ($change_x, $change_y) = (0,0);
    $change_x = 0 - $player_vel * $dt if $sequencia eq 'esquerda';
    $change_x = $player_vel * $dt if $sequencia eq 'direita';
    $change_y = 0 - $player_vel * $dt if $sequencia eq 'cima';
    $change_y = $player_vel * $dt if $sequencia eq 'baixo';

    my $tilex = int(($player_x + $change_x + 15) / $tilesize);
    my $tiley = int(($player_y + $change_y + 35) / $tilesize);

    unless ($mapa->colisao->[$tilex][$tiley]) {
        $player_x += $change_x;
        $player_y += $change_y;
    }


}


sub move_zumbis { $_->tick($_[0], $mapa, $player_x, $player_y) for @zumbis }

sub exibicao {
    my $result = (SDL::get_ticks() - $initial_ticks )/1000;
    $mapa->render( $tela->surface, $result );
    $_->render($tela->surface) for @morrendo;
    $_->render($tela->surface) for @tiros;
    $_->render($tela->surface) for @zumbis;
    $player->draw_xy( $tela->surface, $player_x, $player_y );
    $tela->update;
}

sub eventos_gameover {
    my $e = shift;
    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

    if ( $e->type == SDL_KEYDOWN ) {
        my $tecla = $e->key_sym;
        if ($tecla == SDLK_RETURN || $tecla == SDLK_1 || $tecla == SDLK_2) {

            if ($tecla == SDLK_1) {
                $player = $heroi;
            } elsif ($tecla == SDLK_2) {
                $player = $heroina;
            }

            @zumbis = ();
            @morrendo = ();
            @tiros = ();
            ( $player_x, $player_y ) = $mapa->playerstart_px;
            $player->sequence('parado_baixo');
            init_game();
        }
    }
    return 1;
}

sub render_gameover {
    $telagameover->render($tela);
    $tela->update;
}

sub init_game {
    $jogo->remove_all_handlers;
    $initial_ticks = SDL::get_ticks;
    $jogo->add_event_handler( \&eventos );
    $jogo->add_show_handler( \&exibicao );
    $jogo->add_move_handler( \&move_heroi );
    $jogo->add_move_handler( \&cria_zumbis );
    $jogo->add_move_handler( \&move_zumbis );
}

sub init_game_over {
    %pressed = ();
    $jogo->remove_all_handlers;
    my $result = (SDL::get_ticks() - $initial_ticks )/1000;
    $telagameover = Zumbis::TelaGameOver->new(surface => $tela,
                                              tempo => $result );
    $tela->update();
    $jogo->add_event_handler( \&eventos_gameover );
    #$jogo->add_move_handler( \&animar_gameover );
    $jogo->add_show_handler( \&render_gameover );
}

$jogo = SDLx::Controller->new(dt => 0.3);
init_game();
$jogo->run;

SDL::quit;

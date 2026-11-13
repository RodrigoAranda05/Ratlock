event_inherited();
// VARIÁVEL DA ROOM: "direcao" = para onde as pontas apontam (0 cima = no chão, 1 baixo = no teto, 2 esquerda = na parede da direita, 3 direita = na parede da esquerda).
// A checagem que mata fica em espinho_toca() (scr_colisao).
simbolo = ["^", "V", "<", ">"][direcao];

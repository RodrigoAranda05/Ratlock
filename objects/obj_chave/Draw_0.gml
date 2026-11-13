if (estado == "carried") exit;
var bob = (estado == "home") ? sin(global.tempo_jogo * 3) * 2 : 0;
var kx = x + 3, ky = y + 3;
desenha_brilho(kx, ky, 22, 0.35);
desenha_sprite_agua(spr_chave, 0, kx, ky + bob, 1, 1, 1, superficie_agua(kx, ky + 6));
if (estado == "free")
{
    desenha_rect(kx - 8, ky - 14, 16, 4, 0x000000);
    desenha_rect(kx - 7, ky - 13, 14 * (1 - tempo_livre / 12), 2, (tempo_livre > 8 && floor(global.tempo_jogo * 8) % 2 == 1) ? 0xff4444 : 0xffd23f);
}

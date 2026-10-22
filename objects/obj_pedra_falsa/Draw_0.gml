draw_self();
// perto do rato a parede falsa escurece (dica de que dá pra atravessar)
if (instance_exists(global.jogador))
{
    var p = global.jogador;
    if (abs(p.x + 5 - x - 8) < 22 && abs(p.y + 5 - y - 8) < 22) desenha_rect_alfa(x, y, TL, TL, 0x07090e, 0.62);
}

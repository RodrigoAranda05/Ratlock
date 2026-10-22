event_inherited();
simbolo = "m";          // poça: conduz a eletricidade enquanto houver cabo ligado

// o obj_game chama a cada quadro: o rato com os pés dentro da água eletrificada morre
atualiza = function()
{
    if (!global.energia) return;
    var p = global.jogador;
    var tocando_x = (coluna >= floor(p.x / TL) && coluna <= floor((p.x + p.w - 0.01) / TL));
    var tocando_y = (linha >= floor(p.y / TL) && linha <= floor((p.y + p.h - 1) / TL));
    if (tocando_x && tocando_y && p.y + p.h > linha * TL + 11)
    {
        faiscas(p.x + 5, p.y + 8, 20);
        p.morre();
    }
}

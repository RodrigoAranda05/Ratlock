// ===== obj_queijo: queijo opcional da fase =====
coluna = floor(x / TL);
linha = floor(y / TL);
x += 8;
y += 8;
pego = false;
depth = -1;

atualiza = function()
{
    var p = global.jogador;
    if (!pego && point_distance(x, y, p.x + p.w / 2, p.y + p.h / 2) < 12)
    {
        pego = true;
        faiscas(x, y, 18);
        mostra_aviso("Queijo encontrado!", 2.5);
    }
}

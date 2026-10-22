// ===== obj_queijo: queijo opcional da fase =====
coluna = floor(x / TL);
linha = floor(y / TL);
x += 8;
y += 8;
pego = false;
secreto = false;        // escondido numa parede falsa: só aparece quando o rato chega perto
depth = -1;

// chamado pelo obj_game com a grade pronta: parede falsa por perto = queijo secreto
prepara = function()
{
    for (var a = -1; a <= 1; a++)
    {
        for (var b = -1; b <= 1; b++)
        {
            if (linha + b >= 0 && linha + b < GH && coluna + a >= 0 && coluna + a < GW && global.grade[linha + b][coluna + a] == "f") secreto = true;
        }
    }
}

atualiza = function()
{
    var p = global.jogador;
    if (!pego && point_distance(x, y, p.x + 5, p.y + 5) < 12)
    {
        pego = true;
        faiscas(x, y, 18);
        mostra_aviso("Queijo encontrado!", 2.5);
    }
}

event_inherited();
// VARIÁVEL DA ROOM: "direcao" = para onde o feixe sai (0 direita, 1 cima, 2 esquerda, 3 baixo).
// Cada laser pode apontar para um lado diferente.
simbolo = ["i", "z", "I", "x"][direcao];
vetor = dir_laser(simbolo);                     // [dx, dy] do feixe
quadro_base = [0, 3, 1, 2][direcao];            // grupo de quadros do sprite para esta direção
// VARIÁVEL DA ROOM: "fase_pulso" (0..9) = em que momento do ciclo o laser pulsa. -1 = automático pela posição.
defasagem = ((fase_pulso >= 0) ? fase_pulso : ((coluna * 7 + linha * 3) % 10)) * 0.32;
ligado = false;                                 // feixe ligado
aviso = false;                                  // piscando antes de ligar
tamanho = 0;
feixe = {x: 0, y: 0, w: 0, h: 0};               // retângulo do feixe

// comprimento do feixe até bater em algo sólido ou numa caixa
mede_feixe = function()
{
    var xx = coluna * TL + 8 + vetor[0] * 8;
    var yy = linha * TL + 8 + vetor[1] * 8;
    var n = 0;
    while (n < 160)
    {
        var bateu = solido_rato(floor(xx / TL), floor(yy / TL));
        if (!bateu)
        {
            for (var k = 0; k < array_length(global.caixas); k++)
            {
                var cx = global.caixas[k];
                if (xx >= cx.x && xx < cx.x + cx.w && yy >= cx.y && yy < cx.y + cx.h) bateu = true;
            }
        }
        if (bateu) break;
        xx += vetor[0] * 4;
        yy += vetor[1] * 4;
        n++;
    }
    return n * 4;
}

// ciclo de 3,2 s: ligado 1,8 s, aviso antes de ligar; apaga junto com a luz
atualiza = function()
{
    var p = global.jogador;
    var ciclo = (global.relogio_laser + defasagem) % 3.2;
    ligado = global.luz_ligada && ciclo < 1.8;
    aviso = global.luz_ligada && !ligado && ciclo > 2.7;
    tamanho = mede_feixe();
    var ini_x = coluna * TL + 8 + vetor[0] * 8;
    var ini_y = linha * TL + 8 + vetor[1] * 8;
    if (vetor[0] != 0) feixe = {x: (vetor[0] > 0) ? ini_x : ini_x - tamanho, y: ini_y - 2, w: tamanho, h: 4};
    else feixe = {x: ini_x - 2, y: (vetor[1] > 0) ? ini_y : ini_y - tamanho, w: 4, h: tamanho};
    if (ligado && retangulos_batem({x: p.x + 1, y: p.y + 1, w: p.w - 2, h: p.h - 2}, feixe)) p.morre();
}

// ===== obj_porta: saída da fase (abre com a chave na boca) =====
coluna = floor(x / TL);
linha = floor(y / TL);
depth = 20;

// o rato encostou na porta: com a chave, a fase termina
atualiza = function()
{
    var p = global.jogador;
    if (retangulos_batem(p, {x: coluna * TL, y: (linha - 1) * TL, w: TL, h: 2 * TL}))
    {
        if (global.tem_chave) fase_concluida();
    }
}

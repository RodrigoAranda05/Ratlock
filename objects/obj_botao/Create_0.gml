// ===== obj_botao: botão de chão =====
// VARIÁVEIS DA ROOM:
//   cor           0 vermelho, 1 azul, 2 verde, 3 amarelo
//   comeca_ativo  1 = a fase começa com este botão já ativo (vale só o primeiro criado com 1)
// Não entra na grade de colisão.
coluna = floor(x / TL);
linha = floor(y / TL);
pisado = false;         // tem rato ou caixa em cima agora
com_caixa = false;      // tem uma caixa em cima agora
depth = 40;
image_speed = 0;
sprite_index = [spr_botao_0, spr_botao_1, spr_botao_2, spr_botao_3][cor];

// pisado pelo rato ou por uma caixa. Pede para o obj_game trocar a cor ativa,
// a menos que outro botão ativo esteja preso por uma caixa (aí a cor não muda).
atualiza = function()
{
    var p = global.jogador;
    var area = {x: coluna * TL + 2, y: linha * TL + 10, w: 12, h: 6};
    com_caixa = false;
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        if (retangulos_batem(global.caixas[k], area)) com_caixa = true;
    }
    pisado = com_caixa || retangulos_batem(p, area);
    if (!pisado || cor == global.cor_ativa) return;

    var travado = false;
    with (obj_botao)
    {
        if (id != other.id && com_caixa && cor == global.cor_ativa) travado = true;
    }
    if (!travado) global.cor_pendente = cor;
}

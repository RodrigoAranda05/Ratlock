// ===== obj_inimigo: pai de guardas, cão, caçador e sentinela =====
// A room coloca a instância no canto do tile (o inimigo fica com os pés na base dele). Os filhos escolhem o
// "tipo" e chamam ajusta_tipo(). Para ele patrulhar precisa haver chão sob os pés; o obj_game chama
// prepara_patrulha() quando abre a fase e atualiza() a cada quadro.
coluna = floor(x / TL);
linha = floor(y / TL);
tipo = "G";            // G guarda, L lanterna, N noturno, F eletricista, C cão, H caçador, T sentinela
w = 12;
h = 22;
velh = 0;
velv = 0;
face = -1;           // direção que olha: 1 direita, -1 esquerda
alerta = 0;             // 1 quando viu o rato
memoria = 0;            // quanto tempo ainda lembra
ciclo = 0;             // relógio da sentinela
tempo_cone = 0;     // tempo no cone da sentinela
alarme = false;
cego = false;      // sem ver (luz apagada / sentinela)
no_escuro = false;       // eletricista no escuro
trepando = 0;             // 1 escalando um cano
reparo = 0;         // progresso do reparo do cabo
travado = 0;
ativo = false;
avisando = false;
patrulha_ini = 0;              // limites da patrulha
patrulha_fim = 0;
caca_ini = 0;                  // limites da perseguição (inclui degraus de 1 tile, que o inimigo pula)
caca_fim = 0;
chao = false;                  // está pisando no chão
indo_cabo = false;             // o eletricista está indo religar um cabo
depth = -5;
image_speed = 0;

// tamanho, posição e sprite de acordo com o tipo
ajusta_tipo = function()
{
    w = 12; h = 22;
    if (tipo == "C") { w = 16; h = 10; }
    else if (tipo == "H") { w = 14; h = 9; }
    else if (tipo == "T") { w = 16; h = 24; }
    x = coluna * TL + (TL - w) / 2;
    y = (linha + 1) * TL - h;
    switch (tipo)
    {
        case "G": sprite_index = spr_guarda_g; break;
        case "L": sprite_index = spr_guarda_l; break;
        case "N": sprite_index = spr_guarda_n; break;
        case "F": sprite_index = spr_guarda_f; break;
        case "C": sprite_index = spr_cao; break;
        case "H": sprite_index = spr_cacador; break;
        case "T": sprite_index = spr_sentinela; break;
    }
}

// área de patrulha (até onde o chão é reto); chamado depois que a grade existe
prepara_patrulha = function()
{
    // colocado dentro do chão (no tile do piso em vez do tile de cima)? sobe até achar um tile livre
    var fileira = floor((y + h - 1) / TL);
    var meio_col = floor((x + w / 2) / TL);
    while (fileira > 0 && solido_inimigo(meio_col, fileira))
    {
        y -= TL;
        fileira--;
    }
    if (tipo == "T") return;
    atualiza_limites();
}

// próximo passo de quem anda pela fileira _fileira: retorna quantas colunas avança (0 = não dá para passar).
// _degraus = true: um degrau de 1 tile (pedra ou grade) também conta, porque o inimigo pula na perseguição.
passo_andavel = function(_col, _dir, _fileira, _degraus)
{
    var c = _col + _dir;
    if (!solido_inimigo(c, _fileira)) return solido_inimigo(c, _fileira + 1) ? 1 : 0;       // chão normal ou buraco
    if (!_degraus) return 0;
    if (solido_inimigo(c, _fileira - 1) || solido_inimigo(c, _fileira - 2)) return 0;       // alto demais
    if (solido_inimigo(c + _dir, _fileira) || !solido_inimigo(c + _dir, _fileira + 1)) return 0;  // sem lugar para cair
    return 2;
}

// quanto o chão é reto para cada lado. É recalculado a cada quadro: portões abertos e pisos de cor mudam o caminho.
atualiza_limites = function()
{
    var fileira = floor((y + h - 1) / TL);
    var meio_col = floor((x + w / 2) / TL);
    for (var passada = 0; passada < 2; passada++)
    {
        var degraus = (passada == 1);
        var esq_col = meio_col;
        var dir_col = meio_col;
        var n = passo_andavel(esq_col, -1, fileira, degraus);
        while (n > 0) { esq_col -= n; n = passo_andavel(esq_col, -1, fileira, degraus); }
        n = passo_andavel(dir_col, 1, fileira, degraus);
        while (n > 0) { dir_col += n; n = passo_andavel(dir_col, 1, fileira, degraus); }
        if (!degraus) { patrulha_ini = esq_col * TL; patrulha_fim = (dir_col + 1) * TL - w; }
        else { caca_ini = esq_col * TL; caca_fim = (dir_col + 1) * TL - w; }
    }
}

// tem um degrau de 1 tile (pedra, grade ou caixa) logo à frente e espaço para pular por cima?
degrau_a_frente = function()
{
    var fileira = floor((y + h - 1) / TL);
    var fx = (face > 0) ? x + w + 10 : x - 10;
    var col = floor(fx / TL);
    if (solido_inimigo(col, fileira) && !solido_inimigo(col, fileira - 1) && !solido_inimigo(col, fileira - 2)) return true;
    var alvo = {x: (face > 0) ? x + w : x - 10, y: y, w: 10, h: h};
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        var b = global.caixas[k];
        if (retangulos_batem(alvo, b) && b.y + b.h > y + h - 1 && b.y >= y + h - TL - 1 && !solido_inimigo(col, fileira - 1) && !solido_inimigo(col, fileira - 2)) return true;
    }
    return false;
}

// o cabo é alcançável? O cano tem de ir do chão dele até logo abaixo do cabo, e o caminho até o pé do cano tem de estar livre agora.
alcanca_cabo = function(_cb)
{
    var fileira = floor((y + h - 1) / TL);
    var col_cabo = floor(_cb.x / TL);
    var linha_cabo = floor(_cb.y / TL);
    for (var r = linha_cabo + 1; r <= fileira; r++)
    {
        if (!tile_escalavel(col_cabo, r)) return false;
    }
    var meio_col = floor((x + w / 2) / TL);
    var dir = sign(col_cabo - meio_col);
    if (dir == 0) return true;
    var alvo = col_cabo - dir;
    var c = meio_col;
    var passos = 0;
    while ((alvo - c) * dir > 0 && passos < 40)
    {
        var n = passo_andavel(c, dir, fileira, true);
        if (n == 0) return false;
        c += n * dir;
        passos++;
    }
    return true;
}

// o guarda noturno (lanterna) está perto o bastante para "emprestar" visão no escuro?
perto_de_lanterna = function()
{
    for (var k = 0; k < array_length(global.inimigos); k++)
    {
        var outro = global.inimigos[k];
        if (outro.tipo == "N" && point_distance(outro.x, outro.y, x, y) < 64) return true;
    }
    return false;
}

// está dentro de uma caixa? (inimigos não atravessam caixas)
esta_na_caixa = function()
{
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        if (retangulos_batem(self, global.caixas[k])) return true;
    }
    return false;
}

// comportamento a cada quadro (chamado pelo obj_game, depois do rato)
// preso dentro de uma caixa (não deveria acontecer): sai para o lado livre mais perto
desencalha = function()
{
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        var b = global.caixas[k];
        if (!retangulos_batem(self, b)) continue;
        var esq = b.x - w;
        var dir = b.x + b.w;
        var ficou = x;
        x = (x + w / 2 < b.x + b.w / 2) ? esq : dir;
        if (tile_sobreposto(self, solido_inimigo) != undefined) x = (x == esq) ? dir : esq;
        if (tile_sobreposto(self, solido_inimigo) != undefined) x = ficou;
    }
}

atualiza = function()
{
    desencalha();
    if (chao && tipo != "T") atualiza_limites();
    indo_cabo = false;
    var p = global.jogador;
    var px = p.x + 5;
    var ex = x + w / 2;
    var dx = px - ex;
    var dy = p.y + p.h - y - h;

    if (tipo == "T")
    {
        // sentinela: feixe em ciclos de 4,2 s
        ciclo = (ciclo + DT) % 4.2;
        cego = !global.luz_ligada;
        ativo = !cego && ciclo < 1.8;
        avisando = !cego && ciclo > 3.7;
        var fy = y + h;
        var no_cone = !p.escondido && p.x + p.w > ex - 176 && p.x < ex && p.y + p.h > fy - 48 && p.y < fy && tem_visao(ex, fy - 14, px, p.y + 5);
        if (ativo && no_cone)
        {
            tempo_cone += DT;
            if (tempo_cone > 0.3) p.morre();
        }
        else tempo_cone = 0;
        return;
    }

    cego = (tipo == "L" && !global.luz_ligada && !perto_de_lanterna());
    no_escuro = (tipo == "F" && !global.luz_ligada && !perto_de_lanterna());
    if (no_escuro) { alerta = 0; memoria = 0; }

    var alcance = (tipo == "H") ? 130 : 90;
    var enxerga = false;
    if (tipo == "C")
    {
        // o cão fareja até no barril
        enxerga = (abs(dx) < 120 && abs(dy) < 40);
    }
    else
    {
        enxerga = (!no_escuro && !p.escondido && abs(dy) < 30 && abs(dx) < alcance && (tipo == "H" || sign(dx) == face) && tem_visao(ex, y + 6, px, p.y + 5));
    }

    var velocidade = 0;
    trepando = 0;
    if (!cego)
    {
        if (enxerga) { alerta = 1; memoria = 1.2; }
        else if (alerta != 0)
        {
            memoria -= DT;
            if (memoria <= 0) alerta = 0;
        }
        if (alarme) alerta = 1;
        if (alerta != 0)
        {
            face = (dx > 0) ? 1 : -1;
            velocidade = (tipo == "H") ? 92 : ((tipo == "C") ? 128 : 82);
            if (tipo == "H") { if (abs(dx) < 3) velocidade = 0; }
            else if ((face > 0 && x >= caca_fim + 8) || (face < 0 && x <= caca_ini - 8)) velocidade = 0;
        }
        else
        {
            // eletricista: vai religar o cabo roído mais próximo
            var cabo_alvo = undefined;
            if (tipo == "F")
            {
                var melhor_dist = 99999;
                for (var q = 0; q < array_length(global.cabos); q++)
                {
                    var cb = global.cabos[q];
                    if (cb.roido && abs(cb.x - ex) < melhor_dist && alcanca_cabo(cb)) { melhor_dist = abs(cb.x - ex); cabo_alvo = cb; }
                }
            }
            if (cabo_alvo != undefined)
            {
                indo_cabo = true;
                var d = cabo_alvo.x - ex;
                var cy = y + h / 2;
                var dist_y_cabo = cabo_alvo.y - cy;
                if (abs(d) < 14 && abs(dist_y_cabo) < 24)
                {
                    velocidade = 0;
                    if (dist_y_cabo < -4 && tile_escalavel(floor(cabo_alvo.x / TL), floor(cy / TL))) trepando = 1;
                    reparo += DT;
                    if (random(1) < 0.3) faiscas(cabo_alvo.x, cabo_alvo.y, 1);
                    if (reparo > 2.2)
                    {
                        cabo_alvo.roido = false; global.luz_ligada = true; reparo = 0; travado = 0;
                        faiscas(cabo_alvo.x, cabo_alvo.y, 20);
                        mostra_aviso("O eletricista religou a luz!", 3);
                    }
                }
                else if (abs(d) < 14 && dist_y_cabo <= -24 && tile_escalavel(floor(cabo_alvo.x / TL), floor(cy / TL)))
                {
                    velocidade = 0; trepando = 1; reparo = 0;
                    y -= 55 * DT;
                }
                else
                {
                    reparo = 0;
                    face = (d > 0) ? 1 : -1;
                    velocidade = 62;
                }
            }
            else
            {
                reparo = 0; travado = 0;
                velocidade = (tipo == "H") ? 30 : ((tipo == "C") ? 55 : 42);
                if (x <= patrulha_ini) face = 1;
                if (x >= patrulha_fim) face = -1;
            }
        }
    }
    // perseguindo (ou indo ao cabo): pula degraus de 1 tile, como uma caixa ou um bloco
    if (chao && velocidade != 0 && (alerta != 0 || indo_cabo) && degrau_a_frente()) { velv = -250; chao = false; }
    velh = face * velocidade;
    var bateu = move_x_grade(self, velh * DT, solido_inimigo);
    if (!bateu && esta_na_caixa()) { x -= velh * DT; bateu = true; }
    if (bateu && alerta == 0)
    {
        var tem_cabo_roido = false;
        for (var q = 0; q < array_length(global.cabos); q++)
        {
            if (global.cabos[q].roido) tem_cabo_roido = true;
        }
        if (indo_cabo) travado = 1;
        else face = -face;
    }
    chao = false;
    if (trepando != 0) velv = 0;
    else
    {
        velv = min(velv + 900 * DT, 400);
        if (move_y_grade(self, velv * DT, solido_inimigo)) { chao = (velv > 0); velv = 0; }
    }
    // contato: quem já te viu mata até no barril; o cão sempre mata
    if (!cego && !no_escuro && (!p.escondido || tipo == "C" || alerta != 0) && retangulos_batem(p, {x: x + 2, y: y + 2, w: w - 4, h: h - 3})) p.morre();
}

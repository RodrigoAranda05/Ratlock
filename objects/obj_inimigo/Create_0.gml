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
    var esq_col = meio_col;
    var dir_col = meio_col;
    while (!solido_inimigo(esq_col - 1, fileira) && solido_inimigo(esq_col - 1, fileira + 1)) esq_col--;
    while (!solido_inimigo(dir_col + 1, fileira) && solido_inimigo(dir_col + 1, fileira + 1)) dir_col++;
    patrulha_ini = esq_col * TL;
    patrulha_fim = (dir_col + 1) * TL - w;
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
            else if ((face > 0 && x >= patrulha_fim + 8) || (face < 0 && x <= patrulha_ini - 8)) velocidade = 0;
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
                    if (cb.roido && abs(cb.x - ex) < melhor_dist) { melhor_dist = abs(cb.x - ex); cabo_alvo = cb; }
                }
            }
            if (cabo_alvo != undefined)
            {
                var d = cabo_alvo.x - ex;
                var cy = y + h / 2;
                var dist_y_cabo = cabo_alvo.y - cy;
                if (abs(d) < 22 && abs(dist_y_cabo) < 24)
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
                else if (abs(d) < 24 && dist_y_cabo <= -24 && tile_escalavel(floor(cabo_alvo.x / TL), floor(cy / TL)))
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
        if (tipo == "F" && tem_cabo_roido) travado = 1;
        else face = -face;
    }
    if (trepando != 0) velv = 0;
    else
    {
        velv = min(velv + 900 * DT, 400);
        if (move_y_grade(self, velv * DT, solido_inimigo)) velv = 0;
    }
    // contato: quem já te viu mata até no barril; o cão sempre mata
    if (!cego && !no_escuro && (!p.escondido || tipo == "C" || alerta != 0) && retangulos_batem(p, {x: x + 2, y: y + 2, w: w - 4, h: h - 3})) p.morre();
}

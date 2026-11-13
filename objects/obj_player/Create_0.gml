// ===== obj_player: o rato =====
// Mesmo estilo do seu código: variáveis em #region, pega_input(), checa_chao(), estados como funções
// (estado_parado / estado_movendo / estado_pulo) trocando a variável "estado".
// Diferença importante: aqui x,y é o canto superior esquerdo da caixa 12x19 e as velocidades são em
// pixels por SEGUNDO (os valores foram afinados na versão web, que roda com passo fixo de 1/60 s = DT).
// A colisão é feita contra a grade do mapa (tile_em / solido_rato), não contra uma obj_parede, porque os
// portões, pisos, ventoinhas e lasers mudam de estado durante a fase.

#region variaveis

w = 12;
h = 19;

velh = 0;               // velocidade horizontal (px/s)
velv = 0;               // velocidade vertical (px/s)
max_velh = 80;          // andar
grav = 900;             // gravidade (px/s²)
max_velv = 420;         // velocidade máxima de queda
pulo_forca = -255;      // força do pulo (com a chave na boca é -195)

face = 1;               // 1 = olhando pra direita, -1 = esquerda
chao = false;

// escalar o cano (vinha, no segundo plano): 0 = solto, 1 = agarrado
escalando = 0;
no_cipo = false;                // o corpo está na frente de um cano
col_cipo = 0;                   // coluna (tile) do cano
tecla_cima = false;             // W / seta pra cima (sobe no cano)

tempo_coyote = 0;             // tempo extra para pular depois de sair da borda
buffer_pulo = 0;        // lembra o botão de pulo apertado um pouco antes de tocar o chão

roendo = 0;             // tempo restante roendo um cabo
cabo_alvo = undefined;

morto = false;
tempo_morte = 0;
morte_particulas = [];     // partículas da explosão no estilo celeste quando o rato morre
desce_plat = 0;         // tempo atravessando uma plataforma de mão única (descendo)
tempo_derrapa = 0;      // intervalo entre as nuvens de poeira ao virar
tempo_baixo_plat = 0;   // há quanto tempo segura S em cima de uma plataforma
tempo_ar = 0;           // só desenho: tempo no ar (quadros do pulo)
tempo_queda = 0;        // só desenho: tempo caindo (quadros da queda)
escondido = false;      // dentro de um barril
tempo_anim = 0;
tempo_largou_cano = 0;            // tempo depois de soltar o cano
tempo_duto = 0;           // tempo antes de poder usar outro duto
duto_atual = noone;
teleporte = undefined;  // struct {tempo, destino, meio} enquanto atravessa um duto
queda_max = 0;

// Variaveis de input
tecla_dir = false;
tecla_esq = false;
pulo_apertou = false;           // apertou agora (pressionado)
pulo_segurando = false;      // segurando o pulo (controla a altura)
tecla_baixo = false;
agarra_apertou = false;           // E: agarrar / soltar o cano
roi_segurando = false;           // Q: roer cabo (segurando)
solta_apertou = false;           // G: soltar / lançar a chave

// Variaveis de estado
estado = noone;
// a room coloca o rato no canto de um tile da grade; ele nasce em pé no chão desse tile
x = floor(x / TL) * TL + (TL - w) / 2;
y = (floor(y / TL) + 1) * TL - h;
inicio_x = x;              // posição inicial da fase (onde a room colocou o rato)
inicio_y = y;
global.jogador = id;
depth = -20;
anim_nome = "parado";

#endregion


#region player funções

pega_input = function()
{
    tecla_dir = keyboard_check(ord("D")) or keyboard_check(vk_right);
    tecla_esq = keyboard_check(ord("A")) or keyboard_check(vk_left);
    pulo_apertou = keyboard_check_pressed(vk_space) or keyboard_check_pressed(ord("W")) or keyboard_check_pressed(vk_up);
    pulo_segurando = keyboard_check(vk_space) or keyboard_check(ord("W")) or keyboard_check(vk_up);
    tecla_cima = keyboard_check(ord("W")) or keyboard_check(vk_up);
    tecla_baixo = keyboard_check(ord("S")) or keyboard_check(vk_down);
    agarra_apertou = keyboard_check_pressed(ord("E"));
    roi_segurando = keyboard_check(ord("Q"));
    solta_apertou = keyboard_check_pressed(ord("G"));

    // o resto do jogo (chave, menus) lê as mesmas entradas
    global.teclas.dir = tecla_dir; global.teclas.esq = tecla_esq; global.teclas.cima = pulo_segurando; global.teclas.baixo = tecla_baixo;
    global.teclas.agarra = false; global.teclas.roi = roi_segurando;
    global.teclas.pulo_apertou = pulo_apertou; global.teclas.agarra_apertou = agarra_apertou; global.teclas.solta_apertou = solta_apertou;
}

// o corpo está na frente de um cano? (o cano é segundo plano: não bate, só dá para agarrar)
detecta_cipo = function()
{
    col_cipo = floor((x + w / 2) / TL);
    no_cipo = false;
    // só conta o cano que o corpo cobre de verdade: a cabeça encostando por 1-5 px na célula do cano de cima não agarra
    for (var j = floor((y + 6) / TL); j <= floor((y + h - 1) / TL); j++)
    {
        if (tile_escalavel(col_cipo, j)) no_cipo = true;
    }
}

// gruda no meio do cano
agarra_cipo = function()
{
    escalando = 1;
    velh = 0; velv = 0;
    move_x_grade(self, col_cipo * TL + (TL - w) / 2 - x, solido_rato);
}

// no chão?
checa_chao = function()
{
    chao = (tile_sobreposto({x: x, y: y + 1, w: w, h: h}, solido_rato) != undefined) || (desce_plat <= 0 && plat_sob(self));
}

// y da superfície da água (poça) em que o rato está, ou -1 se não está na água
na_agua = false;
tempo_chap = 0;
// respingo ao entrar na poça (e um menor ao sair)
checa_agua = function()
{
    var _ag = linha_agua();
    if (_ag != -1 && !na_agua) { espirra(x + w / 2, _ag, abs(velv) / 260); toca_som("snd_agua", 0.8); }
    else if (_ag == -1 && na_agua) espirra(x + w / 2, ultima_agua, 0.3);
    // andando na água: ondinhas, gotas e bolhas a cada passo
    tempo_chap -= DT;
    if (_ag != -1 && !morto && abs(velh) > 12 && chao && tempo_chap <= 0)
    {
        chapinha(x + w / 2 - face * 3, _ag);
        tempo_chap = 0.13;
    }
    if (_ag != -1) ultima_agua = _ag;
    na_agua = (_ag != -1);
}
ultima_agua = 0;

linha_agua = function()
{
    var i = floor((x + w / 2) / TL);
    var j = floor((y + h - 1) / TL);
    if (tile_em(i, j) != "m") return -1;
    while (j > 0 && tile_em(i, j - 1) == "m") j--;
    return j * TL + 3;
}

// ---------- empurrar caixas / ficar em cima delas ----------
empurra_caixas = function()
{
    for (var q = 0; q < array_length(global.caixas); q++)
    {
        var b = global.caixas[q];
        if (!retangulos_batem(self, b) || y + h <= b.y + 2) continue;
        var d = (x + w / 2 < b.x + b.w / 2) ? 1 : -1;
        var quanto = (d > 0) ? x + w - b.x : b.x + b.w - x;
        if (b.move(d * quanto, 0))
        {
            x = (d > 0) ? b.x - w : b.x + b.w;
            velh = 0;
        }
        else { velh *= 0.6; b.poeira_arrasto(d); }
    }
}

caixas_apoio = function()
{
    for (var q = 0; q < array_length(global.caixas); q++)
    {
        var b = global.caixas[q];
        if (!retangulos_batem(self, b)) continue;
        if (velv >= 0 && y + h - b.y <= 10) { y = b.y - h; velv = 0; chao = true; }
        else if (velv < 0) { y = b.y + b.h; velv = 0; }
    }
}

// ---------- tentativa de roer um cabo ----------
tenta_roer = function()
{
    if (roi_segurando && (chao || escalando != 0))
    {
        if (global.tem_chave)
        {
            // com a chave na boca não dá para roer
        }
        else
        {
            for (var q = 0; q < array_length(global.cabos); q++)
            {
                var c = global.cabos[q];
                if (!c.roido && point_distance(c.x, c.y, x + w / 2, y + h / 2) < 24)
                {
                    roendo = 0.6; cabo_alvo = c; velh = 0;
                    return true;
                }
            }
        }
    }
    return false;
}

// E agarra ou solta o cano (clicar uma vez só). Segurar W no ar na frente do cano também agarra.
alterna_agarrar = function()
{
    if (escalando != 0)
    {
        if (agarra_apertou) { escalando = 0; tempo_largou_cano = 0.2; }
        return;
    }
    if (global.tem_chave || !no_cipo || tempo_largou_cano > 0) return;
    if (agarra_apertou || (tecla_cima && !chao && velv >= 0)) agarra_cipo();
}

// ---------- morrer, espinhos e dutos (antes ficavam no obj_game) ----------
morre = function()
{
    if (morto || global.estado != "play" || teleporte != undefined) return;
    if (global.cheat && global.invencivel)
    {
        // invencível: só volta ao começo se cair no vazio
        if (y > GH * TL)
        {
            x = inicio_x;
            y = inicio_y;
            velh = 0; velv = 0;
        }
        return;
    }
    if (!global.cheat) global.stats.mortes++;
    morto = true; tempo_morte = 0; velv = 0; velh = 0; escalando = 0; roendo = 0;
    global.mortes++; global.mortes_fase++; global.piscada = 0.5;
    toca_som("snd_morte");
    // explosão em 8 direções (estilo celeste): o rato some e viram pedaços
    var cx_e = x + w / 2, cy_e = y + h / 2;
    morte_particulas = [];
    for (var k = 0; k < 8; k++)
    {
        var a = (k / 8) * 2 * pi;
        array_push(morte_particulas, {
            x: cx_e, y: cy_e,
            vx: cos(a) * 180, vy: sin(a) * 180,
            vida: 0.55, vida_max: 0.55,
            tam: 3 + (k % 3), cor: (k % 2 == 0) ? 0xf3efe6 : 0x9aa7bd
        });
    }
    // alguns pedaços menores em direções aleatórias
    for (var k = 0; k < 6; k++)
    {
        var a2 = random(2 * pi);
        var v2 = 60 + random(80);
        array_push(morte_particulas, {
            x: cx_e, y: cy_e,
            vx: cos(a2) * v2, vy: sin(a2) * v2 - 40,
            vida: 0.55, vida_max: 0.55,
            tam: 1 + (k % 2), cor: (k % 2 == 0) ? 0x3a3450 : 0xb04a4a
        });
    }
}

// encostou num espinho?
toca_espinho = function()
{
    return espinho_toca(self);
}

// chegou perto de um duto? começa o teletransporte para o duto do par
verifica_dutos = function()
{
    var duto_perto = noone;
    for (var q = 0; q < array_length(global.dutos); q++)
    {
        var duto = global.dutos[q];
        if (point_distance(duto.x, duto.y, x + w / 2, y + h / 2) < 9) { duto_perto = duto; break; }
    }
    if (duto_perto == noone) duto_atual = noone;
    else if (duto_atual == noone && tempo_duto <= 0 && teleporte == undefined && duto_perto.destino != noone)
    {
        teleporte = {tempo: 0, destino: duto_perto.destino, meio: false};
        escalando = 0; velh = 0; velv = 0;
        faiscas(duto_perto.x, duto_perto.y, 8);
        toca_som("snd_duto", 0.8);
    }
}


// ---------- estados especiais ----------
estado_morto = function()
{
    tempo_morte += DT;
    // atualiza as partículas da explosão (gravidade e atrito leve)
    for (var k = 0; k < array_length(morte_particulas); k++)
    {
        var p = morte_particulas[k];
        p.vx *= 0.94;
        p.vy = p.vy * 0.94 + 320 * DT;
        p.x += p.vx * DT;
        p.y += p.vy * DT;
        p.vida -= DT;
    }
    if (tempo_morte > 0.7) { global.fase_nova = false; vai_para(-1); }
}

estado_teleporte = function()
{
    var q = teleporte;
    q.tempo += DT;
    if (q.tempo >= 0.25 && !q.meio)
    {
        q.meio = true;
        var _dc = q.destino.coluna, _dl = q.destino.linha;
        x = _dc * TL + (TL - w) / 2;
        // duto no teto (pedra ou bloco de cor em cima): o rato sai pendurado embaixo e cai; senão sai em pé no duto
        var _teto = solido_rato(_dc, _dl - 1) || cor_do_portao(tile_em(_dc, _dl - 1)) >= 0;
        y = (_teto && !solido_rato(_dc, _dl + 1)) ? _dl * TL : (_dl + 1) * TL - h;
        velh = 0; velv = 0;
        duto_atual = q.destino; tempo_duto = 0.5;
        faiscas(q.destino.x, q.destino.y, 10);
    }
    if (q.tempo >= 0.5) teleporte = undefined;
}

estado_roendo = function()
{
    roendo -= DT;
    if (random(1) < 0.4) faiscas(cabo_alvo.x, cabo_alvo.y, 1);
    if (roendo <= 0)
    {
        cabo_alvo.corta();
        cabo_alvo = undefined;
    }
}

// Escalando o cano: W sobe, S desce, A/D andam de lado, espaço pula para fora, E solta.
// Retorna true se o quadro foi consumido pela escalada; false se deve seguir pra física normal.
estado_escalando = function()
{
    var ax = tecla_dir - tecla_esq;
    var gnd = (tile_sobreposto({x: x, y: y + 1, w: w, h: h}, solido_rato) != undefined) || (desce_plat <= 0 && plat_sob(self));
    chao = gnd;
    if (!no_cipo) { escalando = 0; return false; }
    if (ax != 0) face = ax;
    if (keyboard_check_pressed(vk_space))
    {
        // pulo para fora do cano
        velh = ax * 130; velv = -260; escalando = 0; tempo_largou_cano = 0.25;
        return false;
    }
    velh = 0; velv = 0;
    var d = 0;
    if (tecla_cima) d = -1;
    else if (tecla_baixo) d = 1;
    if (d > 0 && gnd) { escalando = 0; return false; }
    if (d < 0 && !tile_escalavel(col_cipo, floor((y + h - 6) / TL)))
    {
        // chegou no topo do cano: um pulinho para subir na borda
        velh = ax * 80; velv = -170; escalando = 0; tempo_largou_cano = 0.2;
        return false;
    }
    if (d != 0) move_y_grade(self, d * 70 * DT, solido_rato);
    if (ax != 0) move_x_grade(self, ax * 50 * DT, solido_rato);
    return true;
}

// ---------- física normal (andar, pular, vento, gravidade) ----------
aplica_velocidade = function()
{
    var ax = tecla_dir - tecla_esq;

    // escondido num barril: só com o S apertado, parado em cima do barril
    escondido = false;
    if (tecla_baixo && chao)
    {
        for (var q = 0; q < array_length(global.barris); q++)
        {
            var bq = global.barris[q];
            if (abs(bq.coluna * TL + 8 - x - w / 2) < 9 && abs((bq.linha + 1) * TL - y - h) < 3) escondido = true;
        }
    }

    // virar de direção correndo: nuvenzinha de poeira nos pés (como no Mario)
    tempo_derrapa -= DT;
    if (chao && !escondido && ax != 0 && sign(velh) == -ax && abs(velh) > 40 && tempo_derrapa <= 0)
    {
        poeira(x + w / 2, y + h, sign(velh), 2);
        tempo_derrapa = 0.07;
    }
    var tv = escondido ? 0 : ax * max_velh;
    velh += (tv - velh) * min(1, DT * (chao ? 20 : 10));
    if (ax != 0 && !escondido) face = ax;

    // plataforma de mão única: só S + pulo desce atravessando (só segurar S não desce: dá para se esconder no barril)
    var so_plat = chao && desce_plat <= 0 && plat_sob(self) && tile_sobreposto({x: x, y: y + 1, w: w, h: h}, solido_rato) == undefined;
    tempo_baixo_plat = (so_plat && tecla_baixo) ? tempo_baixo_plat + DT : 0;
    if (so_plat && tecla_baixo && pulo_apertou)
    {
        desce_plat = 0.25; pulo_apertou = false; buffer_pulo = 0; tempo_coyote = 0; tempo_baixo_plat = 0;
        y += 1; chao = false;
    }

    // pulo com buffer e coyote time
    if (pulo_apertou) buffer_pulo = 0.12;
    buffer_pulo -= DT;
    tempo_coyote = chao ? 0.1 : tempo_coyote - DT;
    if (buffer_pulo > 0 && tempo_coyote > 0 && !escondido)
    {
        velv = global.tem_chave ? -195 : pulo_forca;
        toca_som("snd_pulo", 0.7, global.tem_chave ? 0.85 : 1);
        poeira(x + w / 2, y + h, 0, 4);   // com a chave na boca o pulo é mais fraco
        buffer_pulo = 0; tempo_coyote = 0;
    }
    // soltar o botão corta o pulo (altura variável)
    var corte = global.tem_chave ? -85 : -110;
    if (!pulo_segurando && velv < corte) velv = corte;

    // vento das ventoinhas
    var wi = floor((x + w / 2) / TL);
    var wj = floor((y + h / 2) / TL);
    var wc = "";
    if (global.luz_ligada && wi >= 0 && wi < GW && wj >= 0 && wj < GH) wc = global.mapa_vento[wj][wi];   // sem energia a ventoinha para
    if (wc == "U" || wc == "n") { velv -= 1650 * DT; if (velv < -150) velv = -150; }
    else if (wc == "u") velv += 1100 * DT;
    else if (wc == "R") move_x_grade(self, 75 * DT, solido_rato);
    else if (wc == "y") move_x_grade(self, 95 * DT, solido_rato);
    else if (wc == "Y") move_x_grade(self, -75 * DT, solido_rato);
    else if (wc == "r") move_x_grade(self, -95 * DT, solido_rato);

    velv = min(velv + grav * DT, max_velv);
}

movimento = function()
{
    var _estava_no_chao = chao;
    var _vel_antes = velv;
    if (move_x_grade(self, velh * DT, solido_rato)) velh = 0;
    empurra_caixas();
    chao = false;
    if (move_y_grade(self, velv * DT, solido_rato, desce_plat <= 0))
    {
        if (velv > 0) chao = true;
        velv = 0;
    }
    caixas_apoio();
    if (chao && !_estava_no_chao && _vel_antes > 110) toca_som("snd_pouso", clamp(_vel_antes / 400, 0.3, 0.8));
    if (chao && !_estava_no_chao && _vel_antes > 110) poeira(x + w / 2, y + h, 0, 3 + min(5, floor(_vel_antes / 90)));   // pouso
    if (chao) queda_max = 0;
    else queda_max = max(queda_max, velv);
    if (y > GH * TL + 30) morre();
}

// escolhe o estado de animação pelo que aconteceu no quadro
troca_estado = function()
{
    if (!chao) estado = estado_pulo;
    else if (abs(velh) > 20) estado = estado_movendo;
    else estado = estado_parado;
}

estado_parado = function()
{
    aplica_velocidade();
    movimento();
    anim_nome = "parado";
    troca_estado();
}

estado_movendo = function()
{
    aplica_velocidade();
    movimento();
    anim_nome = "movendo";
    troca_estado();
}

estado_pulo = function()
{
    aplica_velocidade();
    movimento();
    // subindo: velv negativa; caindo: positiva
    anim_nome = (velv < 0) ? "pulo" : "queda";
    troca_estado();
}

// decide o que o rato faz neste quadro
passo = function()
{
    if (global.estado != "play" || transicao_saindo()) return;     // menus e tela de sala concluída: o rato fica parado
    tempo_anim += DT;
    tempo_largou_cano -= DT;
    desce_plat -= DT;
    tempo_duto -= DT;
    if (morto) { estado_morto(); return; }
    if (teleporte != undefined) { estado_teleporte(); return; }
    if (roendo > 0) { estado_roendo(); return; }
    detecta_cipo();
    if (tenta_roer()) return;
    alterna_agarrar();
    if (escalando != 0)
    {
        anim_nome = "escalando";
        if (estado_escalando()) return;
    }
    estado();
}

#endregion


#region debug

view_player = noone;

roda_debug = function()
{
    if (!global.debug) return;
    show_debug_overlay(global.debug);
    view_player = dbg_view("View player", 1, 40, 100, 300, 400);
    dbg_watch(ref_create(id, "velv"), "velv");
    dbg_slider(ref_create(id, "max_velh"), 0, 300, "Max velh", 1);
    dbg_slider(ref_create(id, "grav"), 0, 2000, "Grav", 10);
    dbg_slider(ref_create(id, "pulo_forca"), -600, 0, "Pulo", 1);
}

ativa_debug = function()
{
    if (!DEBUG_MODE) return;
    if (keyboard_check_pressed(vk_tab))
    {
        global.debug = !global.debug;
        if (global.debug) roda_debug();
        else
        {
            show_debug_overlay(0);
            if (dbg_view_exists(view_player)) dbg_view_delete(view_player);
        }
    }
}

#endregion

// Definindo o estado inicial do player
estado = estado_parado;

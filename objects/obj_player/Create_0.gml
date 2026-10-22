// ===== obj_player: o rato =====
// Mesmo estilo do seu código: variáveis em #region, pega_input(), checa_chao(), estados como funções
// (estado_parado / estado_movendo / estado_pulo) trocando a variável "estado".
// Diferença importante: aqui x,y é o canto superior esquerdo da caixa 10x10 e as velocidades são em
// pixels por SEGUNDO (os valores foram afinados na versão web, que roda com passo fixo de 1/60 s = DT).
// A colisão é feita contra a grade do mapa (tile_em / solido_rato), não contra uma obj_parede, porque os
// portões, pisos, ventoinhas e lasers mudam de estado durante a fase.

#region variaveis

w = 10;
h = 10;

velh = 0;               // velocidade horizontal (px/s)
velv = 0;               // velocidade vertical (px/s)
max_velh = 105;         // andar
grav = 900;             // gravidade (px/s²)
max_velv = 420;         // velocidade máxima de queda
pulo_forca = -290;      // força do pulo (com a chave na boca é -230)

face = 1;               // 1 = olhando pra direita, -1 = esquerda
chao = false;

// escalar: 0 = solto, 1 = cano à direita, -1 = cano à esquerda
escalando = 0;
parede_esq = false;             // existe cano encostado à esquerda
parede_dir = false;             // existe cano encostado à direita

tempo_coyote = 0;             // tempo extra para pular depois de sair da borda
buffer_pulo = 0;        // lembra o botão de pulo apertado um pouco antes de tocar o chão

roendo = 0;             // tempo restante roendo um cabo
cabo_alvo = undefined;

morto = false;
tempo_morte = 0;
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
    tecla_baixo = keyboard_check(ord("S")) or keyboard_check(vk_down);
    agarra_apertou = keyboard_check_pressed(ord("E"));
    roi_segurando = keyboard_check(ord("Q"));
    solta_apertou = keyboard_check_pressed(ord("G"));

    // o resto do jogo (chave, menus) lê as mesmas entradas
    global.teclas.dir = tecla_dir; global.teclas.esq = tecla_esq; global.teclas.cima = pulo_segurando; global.teclas.baixo = tecla_baixo;
    global.teclas.agarra = false; global.teclas.roi = roi_segurando;
    global.teclas.pulo_apertou = pulo_apertou; global.teclas.agarra_apertou = agarra_apertou; global.teclas.solta_apertou = solta_apertou;
}

// existe cano encostado nas laterais?
detecta_parede = function()
{
    var meio = floor((y + 5) / TL);
    parede_esq = tile_escalavel(floor((x - 1) / TL), meio);
    parede_dir = tile_escalavel(floor((x + w + 1) / TL), meio);
}

// no chão?
checa_chao = function()
{
    chao = (tile_sobreposto({x: x, y: y + 1, w: w, h: h}, solido_rato) != undefined);
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
        else velh *= 0.6;
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
                if (!c.roido && point_distance(c.x, c.y, x + 5, y + 5) < 24)
                {
                    roendo = 0.6; cabo_alvo = c; velh = 0;
                    return true;
                }
            }
        }
    }
    return false;
}

// E agarra ou solta o cano (clicar uma vez só)
alterna_agarrar = function()
{
    if (!agarra_apertou) return;
    if (escalando != 0) { escalando = 0; tempo_largou_cano = 0.2; }
    else if (global.tem_chave) return;
    else if (parede_esq || parede_dir) escalando = (parede_dir && (!parede_esq || face > 0)) ? 1 : -1;
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
    morto = true; tempo_morte = 0; velv = -230; velh = 0; escalando = 0; roendo = 0;
    global.mortes++; global.mortes_fase++; global.piscada = 0.5;
}

// encostou num espinho?
toca_espinho = function()
{
    for (var j = floor(y / TL); j <= floor((y + h) / TL); j++)
    {
        for (var i = floor(x / TL); i <= floor((x + w) / TL); i++)
        {
            if (tile_em(i, j) == "^" && retangulos_batem(self, {x: i * TL + 2, y: j * TL + 7, w: 12, h: 9})) return true;
        }
    }
    return false;
}

// chegou perto de um duto? começa o teletransporte para o duto do par
verifica_dutos = function()
{
    var duto_perto = noone;
    for (var q = 0; q < array_length(global.dutos); q++)
    {
        var duto = global.dutos[q];
        if (point_distance(duto.x, duto.y, x + 5, y + 5) < 9) { duto_perto = duto; break; }
    }
    if (duto_perto == noone) duto_atual = noone;
    else if (duto_atual == noone && tempo_duto <= 0 && teleporte == undefined && duto_perto.destino != noone)
    {
        teleporte = {tempo: 0, destino: duto_perto.destino, meio: false};
        escalando = 0; velh = 0; velv = 0;
        faiscas(duto_perto.x, duto_perto.y, 8);
    }
}


// ---------- estados especiais ----------
estado_morto = function()
{
    tempo_morte += DT;
    velv += 700 * DT;
    y += velv * DT;
    if (tempo_morte > 0.9) { global.fase_nova = false; room_restart(); }
}

estado_teleporte = function()
{
    var q = teleporte;
    q.tempo += DT;
    if (q.tempo >= 0.25 && !q.meio)
    {
        q.meio = true;
        x = q.destino.coluna * TL + 3; y = (q.destino.linha + 1) * TL - 10;
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

// Escalando o cano: andar em direção à parede sobe, para o lado oposto desce.
// Retorna true se o quadro foi consumido pela escalada; false se deve seguir pra física normal.
estado_escalando = function()
{
    var ax = tecla_dir - tecla_esq;
    var sd = (escalando > 0) ? parede_dir : parede_esq;
    var gnd = (tile_sobreposto({x: x, y: y + 1, w: w, h: h}, solido_rato) != undefined);
    face = escalando;
    chao = gnd;
    if (!sd) { escalando = 0; return false; }
    if (pulo_apertou)
    {
        // pulo da parede
        velh = -escalando * 130; velv = -260; escalando = 0; tempo_largou_cano = 0.25;
        return false;
    }
    velh = 0; velv = 0;
    var d = 0;
    if (ax * escalando > 0) d = -1;          // em direção à parede: sobe
    else if (ax * escalando < 0) d = 1;      // para o lado oposto: desce
    if (d > 0 && gnd) { escalando = 0; return false; }
    if (d < 0)
    {
        var coluna = floor(((escalando > 0) ? x + w + 1 : x - 1) / TL);
        if (!solido_rato(coluna, floor((y - 2) / TL)))
        {
            // chegou no topo do cano: sobe em cima dele
            var r = floor((y + h - 1) / TL);
            while (tile_escalavel(coluna, r - 1)) r--;
            y = r * TL - h;
            x += escalando * 9;
            escalando = 0;
            chao = true;
            return true;
        }
    }
    if (d != 0) move_y_grade(self, d * 70 * DT, solido_rato);
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
            if (abs(bq.coluna * TL + 8 - x - 5) < 9 && abs((bq.linha + 1) * TL - y - h) < 3) escondido = true;
        }
    }

    var tv = escondido ? 0 : ax * max_velh;
    velh += (tv - velh) * min(1, DT * (chao ? 20 : 10));
    if (ax != 0 && !escondido) face = ax;

    // pulo com buffer e coyote time
    if (pulo_apertou) buffer_pulo = 0.12;
    buffer_pulo -= DT;
    tempo_coyote = chao ? 0.1 : tempo_coyote - DT;
    if (buffer_pulo > 0 && tempo_coyote > 0 && !escondido)
    {
        velv = global.tem_chave ? -230 : pulo_forca;   // com a chave na boca o pulo é mais fraco
        buffer_pulo = 0; tempo_coyote = 0;
    }
    // soltar o botão corta o pulo (altura variável)
    var corte = global.tem_chave ? -85 : -110;
    if (!pulo_segurando && velv < corte) velv = corte;

    // vento das ventoinhas
    var wi = floor((x + 5) / TL);
    var wj = floor((y + 5) / TL);
    var wc = "";
    if (wi >= 0 && wi < GW && wj >= 0 && wj < GH) wc = global.mapa_vento[wj][wi];
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
    if (move_x_grade(self, velh * DT, solido_rato)) velh = 0;
    empurra_caixas();
    chao = false;
    if (move_y_grade(self, velv * DT, solido_rato))
    {
        if (velv > 0) chao = true;
        velv = 0;
    }
    caixas_apoio();
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
    if (global.estado != "play") return;     // menus e tela de sala concluída: o rato fica parado
    tempo_anim += DT;
    tempo_largou_cano -= DT;
    tempo_duto -= DT;
    if (morto) { estado_morto(); return; }
    if (teleporte != undefined) { estado_teleporte(); return; }
    if (roendo > 0) { estado_roendo(); return; }
    detecta_parede();
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

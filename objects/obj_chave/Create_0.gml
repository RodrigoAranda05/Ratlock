// ===== obj_chave: a chave da porta =====
casa_x = x + 8;         // lugar de origem (centro do tile)
casa_y = y + 8;
x = casa_x - 3;
y = y + 5;
w = 6;
h = 6;
velh = 0;
velv = 0;
estado = "home";        // home = no lugar, carried = na boca, free = solta no chão
na_agua = false;        // dentro da poça (respinga só ao entrar)
tempo_livre = 0;        // há quanto tempo está solta (volta sozinha depois de 12 s)
espera_pega = 0;        // depois de soltar, demora um pouco para poder pegar de novo
depth = -1;

// o rato larga ou lança a chave (G; com S apertado ela cai quase parada)
solta = function()
{
    var p = global.jogador;
    global.chaves_soltas++;
    estado = "free";
    global.tem_chave = false;
    x = p.x + p.w / 2 + p.face * 5 - 3;
    y = p.y + 1;
    velh = global.teclas.baixo ? p.face * 15 : p.face * 62;
    velv = global.teclas.baixo ? 0 : -190;
    tempo_livre = 0;
    espera_pega = 0.5;
}

// a chave solta encostou num espinho? (mesma caixa de espinho que mata o rato)
toca_espinho = function()
{
    return espinho_toca(self);
}

// volta ao lugar de origem
volta = function(_destruida = false)
{
    estado = "home";
    x = casa_x - 3;
    y = casa_y - 3;
    velh = 0;
    velv = 0;
    tempo_livre = 0;
    faiscas(casa_x, casa_y, 14);
    toca_som("snd_solta");
    mostra_aviso(_destruida ? "A chave foi destruída pelo espinho e voltou ao lugar de origem" : "A chave voltou ao lugar de origem", 2.5);
}

// chamado pelo obj_game a cada quadro
atualiza = function()
{
    var p = global.jogador;
    espera_pega -= DT;
    if (global.teclas.solta_apertou && global.tem_chave) solta();
    if (estado == "free")
    {
        velv = min(velv + 900 * DT, 400);
        if (move_x_grade(self, velh * DT, solido_rato)) velh = 0;
        if (move_y_grade(self, velv * DT, solido_rato, true)) { if (velv > 0) velh = 0; velv = 0; }
        // em cima de um botão ela fica parada fazendo peso: o relógio de 12 s não corre
        var _no_botao = false;
        with (obj_botao) { if (com_caixa && !_no_botao) _no_botao = retangulos_batem(other, {x: coluna * TL + 2, y: linha * TL + 10, w: 12, h: 6}); }
        if (!_no_botao) tempo_livre += DT;
        var _ag = superficie_agua(x + 3, y + 5);
        if (_ag != -1 && !na_agua) { espirra(x + 3, _ag, velv / 300); toca_som("snd_agua", 0.7, 1.3); }
        na_agua = (_ag != -1);
        if (toca_espinho()) { faiscas(x + 3, y + 3, 18); volta(true); return; }
        if (tempo_livre > 12 || y > GH * TL) volta();
    }
    if (estado != "carried" && espera_pega <= 0 && p.escalando == 0 && point_distance(x + 3, y + 3, p.x + p.w / 2, p.y + p.h / 2) < 12)
    {
        estado = "carried";
        global.tem_chave = true;
        tempo_livre = 0;
        toca_som("snd_chave");
        // o caçador dispara quando alguém pega a chave
        with (obj_inimigo)
        {
        }
    }
}

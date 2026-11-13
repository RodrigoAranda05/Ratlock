// ===== obj_caixa: caixa empurrável =====
w = 16;
h = 16;
velh = 0;
velv = 0;
x_inicial = x;          // volta pra cá se cair no vazio
y_inicial = y;
depth = -2;
image_speed = 0;

na_agua = false;        // pés dentro da poça (para respingar só ao entrar)
tempo_poeira = 0;       // intervalo entre as nuvens de poeira ao arrastar

// o rato empurra a caixa: poeira atrás dela
poeira_arrasto = function(_d)
{
    if (tempo_poeira > 0 || velv != 0) return;
    var _agc = superficie_agua(x + w / 2, y + h - 3);
    if (_agc != -1)
    {
        chapinha((_d > 0) ? x : x + w, _agc);       // arrastando na água: respingos em vez de poeira
        tempo_poeira = 0.1;
        return;
    }
    poeira((_d > 0) ? x : x + w, y + h, -_d, 1);
    tempo_poeira = 0.09;
}

// bate em outra caixa?
bate = function(_outra)
{
    return id != _outra.id && x < _outra.x + _outra.w && x + w > _outra.x && y < _outra.y + _outra.h && y + h > _outra.y;
}

// encostou em algo sólido, em outra caixa ou em um inimigo? (a caixa não cai nem entra em cima de guarda/cão:
// ela para em cima da cabeça dele, senão o inimigo ficaria preso dentro dela)
bloqueada = function()
{
    if (tile_sobreposto(self, solido_rato) != undefined) return true;
    for (var k = 0; k < array_length(global.inimigos); k++)
    {
        if (retangulos_batem(self, global.inimigos[k])) return true;
    }
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        if (bate(global.caixas[k])) return true;
    }
    return false;
}

// tenta andar; se bater, desfaz e devolve true
move = function(_dx, _dy)
{
    if (_dx != 0)
    {
        x += _dx;
        if (bloqueada()) { x -= _dx; return true; }
    }
    if (_dy != 0)
    {
        var _antes = y + h;
        y += _dy;
        if (bloqueada()) { y -= _dy; return true; }
        // plataforma de mão única: a caixa pousa em cima dela (vindo de cima)
        if (_dy > 0)
        {
            var _j = floor((y + h) / TL);
            if (_antes <= _j * TL + 0.01)
            {
                for (var _i = floor(x / TL); _i <= floor((x + w - 0.01) / TL); _i++)
                {
                    if (plat_tile(_i, _j, x, x + w)) { y = _j * TL - h; return true; }
                }
            }
        }
    }
    return false;
}

// a caixa cai com a gravidade (chamado pelo obj_game)
atualiza = function()
{
    tempo_poeira -= DT;
    velv = min(velv + 900 * DT, 400);
    var _vel_antes = velv;
    if (move(0, velv * DT))
    {
        velv = 0;
        if (_vel_antes > 140) toca_som("snd_pouso", 0.45, 0.8);
        if (_vel_antes > 140) poeira(x + w / 2, y + h, 0, 4 + min(4, floor(_vel_antes / 100)));   // caiu no chão
    }
    var _ag = superficie_agua(x + w / 2, y + h - 3);
    if (_ag != -1 && !na_agua) { espirra(x + w / 2, _ag, _vel_antes / 300); toca_som("snd_agua", 0.9); }
    na_agua = (_ag != -1);
    if (y > GH * TL + 20) { x = x_inicial; y = y_inicial; velv = 0; }
}

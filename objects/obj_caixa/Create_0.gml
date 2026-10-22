// ===== obj_caixa: caixa empurrável =====
w = 16;
h = 16;
velh = 0;
velv = 0;
x_inicial = x;          // volta pra cá se cair no vazio
y_inicial = y;
depth = -2;
image_speed = 0;

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
        y += _dy;
        if (bloqueada()) { y -= _dy; return true; }
    }
    return false;
}

// a caixa cai com a gravidade (chamado pelo obj_game)
atualiza = function()
{
    velv = min(velv + 900 * DT, 400);
    if (move(0, velv * DT)) velv = 0;
    if (y > GH * TL + 20) { x = x_inicial; y = y_inicial; velv = 0; }
}

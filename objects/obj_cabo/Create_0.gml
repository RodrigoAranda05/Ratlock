// ===== obj_cabo: cabo de energia que o rato pode roer =====
x += 8;                 // centro do tile
y += 8;
coluna = floor(x / TL);
linha = floor(y / TL);
roido = false;
depth = -1;
// VARIÁVEL DA ROOM: desligado (0 normal, 1 a fase COMEÇA SEM ENERGIA: a energia só volta se o eletricista consertar)
if (desligado == 1) roido = true;

// o rato terminou de roer: gasta o cabo; com todos roídos a luz apaga
corta = function()
{
    roido = true;
    global.cabos_roidos++;
    var todos = true;
    for (var i = 0; i < array_length(global.cabos); i++)
    {
        if (!global.cabos[i].roido) todos = false;
    }
    if (todos) global.luz_ligada = false;
    faiscas(x, y, 24);
    toca_som("snd_cabo");
    global.piscada = 0.25;
    mostra_aviso("Cabo roído: energia cortada!", 3);
}

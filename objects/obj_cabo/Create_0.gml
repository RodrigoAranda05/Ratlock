// ===== obj_cabo: cabo de energia que o rato pode roer =====
x += 8;                 // centro do tile
y += 8;
roido = false;
depth = -1;

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
    global.piscada = 0.25;
    mostra_aviso("Cabo roído: energia cortada!", 3);
}

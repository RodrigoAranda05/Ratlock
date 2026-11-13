// morcego-tutorial: parado -> avistou -> voando (sai da fase e some)
if (global.estado != "play" || global.pausa) exit;
tempo += DT;

// 1º quadro: desce até o primeiro bloco sólido e para com os pés em cima dele
// (o corpo do quadro parado ocupa do centro do sprite até 16 px abaixo)
if (!pousou)
{
    pousou = true;
    var _c = floor(x / TL);
    for (var _l = floor(y / TL); _l < GH; _l++)
    {
        if (tile_em(_c, _l) != ".") { y = _l * TL - 16; break; }
    }
}

switch (estado)
{
    case "parado":
        anim = (anim + DT * 8) % 8;                          // quadros 0..7
        balao_pulo = 0;                                      // parado de verdade, sem afundar no bloco
        var p = global.jogador;
        if (instance_exists(p) && !p.morto)
        {
            if (point_distance(x, y, p.x + p.w / 2, p.y + p.h / 2) < raio_ativa)
            {
                estado = "avistou";
                tempo = 0;
                sentido = (p.x + p.w / 2 < x) ? 1 : -1;      // foge para o lado oposto ao rato
            }
        }
        break;

    case "avistou":
        // saltinho de susto antes de abrir as asas
        anim = 7;
        balao_pulo = -4 * sin(min(1, tempo / 0.25) * pi);
        if (tempo >= 0.25)
        {
            estado = "voando";
            tempo = 0;
            anim = 8;
            velh = sentido * 60;
            velv = -80;
            toca_som("snd_pulo");
        }
        break;

    case "voando":
        anim += DT * 12;                                     // quadros 8..13 em loop
        if (anim >= 14) anim -= 6;
        velh = clamp(velh + sentido * 60 * DT, -170, 170);
        velv = max(velv - 40 * DT, -170);
        x += velh * DT;
        y += velv * DT;
        balao_pulo = 0;
        if (y < -40 || x < -40 || x > room_width + 40) instance_destroy();
        break;
}

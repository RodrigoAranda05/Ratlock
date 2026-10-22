// ===== obj_camera: câmera de segurança =====
x += 8;
y += 4;
angulo = pi / 2;        // direção do cone
amplitude = 0.9;        // quanto ela varre para cada lado
tempo = random(6);
tempo_visto = 0;        // há quanto tempo está vendo o rato
ligada = true;
ve_rato = false;
depth = -3;

// se uma câmera vê o rato por um instante, todos os guardas ficam em alerta
dispara_alarme = function()
{
    global.alarme = true;
    with (obj_inimigo)
    {
        if (string_pos(tipo, "GLNCF") > 0) alarme = true;
    }
    mostra_aviso("ALARME! A câmera avisou os guardas", 3);
}

atualiza = function()
{
    var p = global.jogador;
    tempo += DT;
    angulo = pi / 2 + sin(tempo * 0.8) * amplitude;
    ligada = global.luz_ligada;
    var rato_x = p.x + 5, rato_y = p.y + 5;
    var dist_x = rato_x - x, dist_y = rato_y - y;
    var desvio = abs(arctan2(dist_y, dist_x) - angulo);
    if (desvio > pi) desvio = 2 * pi - desvio;
    ve_rato = ligada && !p.escondido && point_distance(0, 0, dist_x, dist_y) < 150 && desvio < 0.33 && tem_visao(x, y, rato_x, rato_y);
    if (ve_rato)
    {
        tempo_visto += DT;
        if (tempo_visto > 0.35 && !global.alarme) dispara_alarme();
    }
    else tempo_visto = max(0, tempo_visto - DT);
}

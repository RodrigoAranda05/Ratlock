if (fugindo)
{
    tempo_voo += DT;
    quadro_bat = 8 + (floor(tempo_voo * 12) mod 6);
    x += vel_voo_x * DT;
    y += vel_voo_y * DT;
    if (x > room_width + 32 || y < -48) instance_destroy();
    exit;
}
var p = global.jogador;
if (!instance_exists(p) || p.morto) { perto = false; exit; }
tempo_anim += DT;
perto = point_distance(x, y, p.x + p.w / 2, p.y + p.h / 2) < 36;
quadro_bat = floor(tempo_anim * 8) mod 8;
if (perto)
{
    fugindo = true;
    tempo_voo = 0;
    vel_voo_x = 54;
    vel_voo_y = -62;
    toca_som("snd_pulo");
}


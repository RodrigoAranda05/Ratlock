var vermelho = (global.alarme || tempo_visto > 0);
if (ligada)
{
    draw_set_alpha(vermelho ? 0.24 : 0.16);
    draw_set_colour(cor_rgb(vermelho ? 0xff3c28 : 0x78ffa0));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(x, y);
    for (var k = 0; k <= 8; k++)
    {
        var a = angulo - 0.33 + k * 0.0825;
        var alcance = 0;
        while (alcance < 150 && !solido_rato(floor((x + cos(a) * alcance) / TL), floor((y + sin(a) * alcance) / TL))) alcance += 4;
        draw_vertex(x + cos(a) * alcance, y + sin(a) * alcance);
    }
    draw_primitive_end();
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
draw_sprite(spr_camera, ligada ? (vermelho ? 1 : 0) : 2, x, y);

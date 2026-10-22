// ===== mundo: vento, partículas e flash (coordenadas da room) =====
if (room != rm_menu && instance_exists(obj_player))
{
    desenha_vento();
    for (var q = 0; q < array_length(global.particulas); q++)
    {
        var fagulha = global.particulas[q];
        desenha_rect(fagulha.x, fagulha.y, 2, 2, fagulha.c);
    }
    if (global.piscada > 0) desenha_rect_alfa(0, 0, room_width, room_height, 0xffffff, global.piscada * 0.5);
}

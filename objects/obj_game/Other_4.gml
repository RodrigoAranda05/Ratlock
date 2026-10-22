// ===== Room Start: prepara a fase que acabou de abrir =====
// Qualquer room que tenha um obj_player é jogável. As rooms só têm instâncias (paredes, guardas, caixas...);
// aqui montamos a grade de colisão e as listas a partir delas.

ajusta_tela();

// sem rato (menu): nada para montar
if (room == rm_menu || !instance_exists(obj_player))
{
    global.jogador = noone;
    exit;
}

// dados da fase: da lista (rm_fase_01...) ou padrão, para uma room de teste que não está na lista
global.fase_atual = array_get_index(global.salas, room);
global.info_fase = (global.fase_atual >= 0) ? global.fases[global.fase_atual] : fase_padrao(room);
if (global.estado == "title" || global.estado == "worlds" || global.estado == "select") global.estado = "play";

if (global.fase_nova)
{
    global.mortes_fase = 0; global.tempo_fase = 0; global.cabos_roidos = 0; global.chaves_soltas = 0;
    global.fase_nova = false;
}
global.cor_ativa = -1; global.cor_pendente = -1; global.alarme = false; global.luz_ligada = true; global.tem_chave = false;
global.particulas = []; global.relogio_laser = 0; global.energia = true;

monta_fase();

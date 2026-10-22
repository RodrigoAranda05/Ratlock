// ===== criador: desenho das telas =====
if (global.estado != "lista_custom" && global.estado != "editor") exit;
gui_comeca();
if (global.estado == "lista_custom") desenha_lista();
else desenha_editor();
gui_termina();

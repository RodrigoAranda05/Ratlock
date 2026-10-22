// ===== criador: teclado e mouse das telas "lista_custom" e "editor" =====
msg_tempo -= DT;
confirma_tempo -= DT;
if (global.estado != "lista_custom" && global.estado != "editor") { estado_visto = global.estado; exit; }

// a tela acabou de abrir neste quadro (o obj_ui ou outro objeto mudou o estado): a tecla que abriu já foi usada
if (estado_visto != global.estado) { estado_visto = global.estado; exit; }

mx = mouse_layout_x();
my = mouse_layout_y();
var tecla_cima = keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
var tecla_baixo = keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"));
var tecla_ok = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
var tecla_esc = keyboard_check_pressed(vk_escape);

if (global.estado == "lista_custom")
{
    var itens = monta_itens();
    var total = array_length(itens);
    lista_cursor = clamp(lista_cursor, 0, total - 1);
    if (tecla_cima) lista_cursor = max(0, lista_cursor - 1);
    if (tecla_baixo) lista_cursor = min(total - 1, lista_cursor + 1);
    if (lista_cursor < lista_rolagem) lista_rolagem = lista_cursor;
    if (lista_cursor >= lista_rolagem + 9) lista_rolagem = lista_cursor - 8;
    var item = itens[lista_cursor];

    if (keyboard_check(vk_control) && keyboard_check_pressed(ord("V"))) importa_clipboard();
    else if (tecla_esc) { global.estado = "title"; room_goto(rm_menu); }
    else if (tecla_ok)
    {
        if (item.t == "novo") { novo_rascunho(); global.estado = "editor"; }
        else if (item.t == "rasc") global.estado = "editor";
        else if (item.t == "imp") importa_clipboard();
        else inicia_custom(global.custom_salvas[item.i], "custom");
    }
    else if (item.t == "fase")
    {
        var f = global.custom_salvas[item.i];
        if (keyboard_check_pressed(ord("E")))
        {
            global.ed = {nome: f.nome, grade: copia_grade(f.grade), validada: true, slot: item.i};
            sel = indice_peca("pedra");
            var_sel = 0;
            global.estado = "editor";
        }
        else if (keyboard_check_pressed(ord("C"))) copiar_codigo(f);
        else if (keyboard_check_pressed(vk_delete))
        {
            if (pede_confirmacao("apagar", "Aperte Del de novo para apagar esta fase")) apaga_fase(item.i);
        }
    }
    exit;
}

// ----- editor -----
var ed = global.ed;

if (nomeando)
{
    ed.nome = limpa_nome(keyboard_string);
    keyboard_string = ed.nome;
    if (tecla_ok)
    {
        nomeando = false;
        if (salva_depois_do_nome) salvar();
    }
    else if (tecla_esc) nomeando = false;
    exit;
}

if (tecla_esc) { global.estado = "lista_custom"; exit; }
if (keyboard_check_pressed(ord("T"))) testar();
else if (keyboard_check_pressed(ord("S"))) salvar();
else if (keyboard_check_pressed(ord("N"))) executa_acao("nome");
else if (keyboard_check_pressed(ord("C"))) copiar_codigo(ed);
else if (keyboard_check_pressed(ord("X"))) limpar();
if (keyboard_check_pressed(ord("R"))) gira_variante();
if (keyboard_check_pressed(ord("Q")) || mouse_wheel_up()) escolhe_peca(sel - 1);
if (keyboard_check_pressed(ord("E")) || mouse_wheel_down()) escolhe_peca(sel + 1);

// mouse: paleta, botões e grade
if (mouse_check_button_pressed(mb_left))
{
    var s = slot_sob_mouse();
    var b = botao_sob_mouse();
    if (s >= 0)
    {
        if (s - 1 == sel) gira_variante();       // clicar de novo na peça escolhida troca a variante
        else escolhe_peca(s - 1);
    }
    else if (b >= 0) executa_acao(botoes[b].acao);
}
var cel = celula_sob_mouse();
if (cel != undefined)
{
    if (mouse_check_button(mb_left)) aplica_celula(cel[0], cel[1], false);
    else if (mouse_check_button(mb_right)) aplica_celula(cel[0], cel[1], true);
}

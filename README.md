# Ordo

> Antes chamado **Tarefas**. Só o nome mudou: atualizar instala por cima e mantém todos os dados.

App pessoal de produtividade para **Windows** e **Android**, com o jeito de usar do TickTick e muito mais: tarefas, calendário, matriz de Eisenhower, Pomodoro, hábitos, contagem regressiva com painel de projeto, finanças, dieta, diário, resumo e estatísticas.

Os dados ficam **só no seu aparelho**: não tem conta, login nem servidor. Para levar os dados de um aparelho para outro, use a sincronização pelo Wi-Fi ou o backup (veja [Backup e troca de aparelho](#backup-e-troca-de-aparelho)).

> Projeto pessoal e independente, sem ligação com o TickTick nem com a Appest. Nome e código são próprios; só o fluxo de uso foi inspirado no app original.

## Sumário

- [Instalar no Windows](#instalar-no-windows)
- [Instalar no Android](#instalar-no-android)
- [Primeiros passos](#primeiros-passos)
- [Todas as funcionalidades](#todas-as-funcionalidades)
  - [Tarefas e listas](#tarefas-e-listas) · [Adição rápida](#adição-rápida) · [Detalhe da tarefa](#detalhe-da-tarefa) · [Lembretes e repetição](#lembretes-e-repetição) · [Visualizações](#visualizações) · [Smart lists, filtros e etiquetas](#smart-lists-filtros-e-etiquetas) · [Seleção em lote](#seleção-em-lote)
  - [Calendário](#calendário) · [Matriz de Eisenhower](#matriz-de-eisenhower) · [Foco (Pomodoro)](#foco-pomodoro) · [Hábitos](#hábitos) · [Contagem regressiva e painel do projeto](#contagem-regressiva-e-painel-do-projeto)
  - [Finanças](#finanças) · [Dieta](#dieta) · [Diário](#diário) · [Resumo](#resumo) · [Estatísticas](#estatísticas)
  - [Busca, paleta e atalhos](#busca-paleta-e-atalhos) · [Ícones (emojis)](#ícones-emojis) · [Aparência e idioma](#aparência-e-idioma)
  - [Widget do celular](#widget-de-calendário-android) · [Mini calendário do PC](#mini-calendário-windows) · [Segundo plano, notificações e sons](#segundo-plano-notificações-e-sons) · [Configurações](#configurações)
- [Backup e troca de aparelho](#backup-e-troca-de-aparelho)
- [Para desenvolver](#para-desenvolver)

---

## Instalar no Windows

### Baixar e instalar (jeito fácil)

1. Abra a página de [**Releases**](https://github.com/FLucasF/Ordo/releases/latest) e baixe o **`OrdoSetup-1.7.0.exe`**.
2. Dê dois cliques no arquivo baixado.
3. O Windows pode mostrar o aviso azul do **SmartScreen** ("O Windows protegeu o computador"), porque o instalador não tem assinatura digital paga. Clique em **Mais informações → Executar assim mesmo**.
4. Siga o instalador: **Avançar → Instalar → Concluir**. Ele não pede senha de administrador e cria o atalho **Ordo** no menu Iniciar. Se você marcar a opção, cria também na área de trabalho.

Funciona no Windows 10 e 11 (64 bits). Não precisa instalar mais nada, porque o instalador já leva tudo o que o app usa.

> **Bloqueio do Controle Inteligente de Aplicativos (Windows 11):** se aparecer "Uma política de Controle de Aplicativo bloqueou este arquivo" ou o erro "desktop_drop_plugin.dll não foi projetado para ser executado no Windows" (0xc0e90002), é essa proteção do Windows bloqueando o app porque os arquivos dele não têm assinatura digital paga (o arquivo não está estragado). Para usar, desligue-a em *Segurança do Windows → Controle de aplicativos e navegador → Configurações do Controle Inteligente de Aplicativos*. Em versões mais antigas do Windows 11, depois de desligada ela só volta reinstalando o Windows; nas recentes dá para religar.

- **Atualizar:** baixe o instalador da versão nova e rode por cima, mesmo com o app aberto na bandeja (o instalador fecha o app sozinho). Seus dados continuam. Quem tinha a versão "Tarefas" ganha os atalhos novos "Ordo".
- **Desinstalar:** use *Configurações do Windows → Aplicativos → Ordo → Desinstalar*. Seus dados **não** são apagados; se instalar de novo, eles voltam.

### Onde ficam os dados

Em `%APPDATA%\dev.lucasfelipe\Tarefas` (a pasta mantém o nome antigo para nada se perder): o banco de dados, os anexos, as imagens de fundo e os backups automáticos. Para apagar tudo de vez, apague essa pasta depois de desinstalar.

### Gerar a partir do código (para quem quer mexer no app)

O que precisa:

- [Git](https://git-scm.com/download/win).
- [Flutter](https://docs.flutter.dev/get-started/install/windows/desktop) 3.47 ou mais novo.
- [Visual Studio 2022](https://visualstudio.microsoft.com/pt-br/downloads/) (a edição Community é gratuita), com a carga de trabalho **"Desenvolvimento para desktop com C++"**. Confira com `flutter doctor`.
- Para gerar o instalador, o [Inno Setup 6](https://jrsoftware.org/isinfo.php), que é gratuito: `winget install JRSoftware.InnoSetup`.

```bash
git clone https://github.com/FLucasF/Ordo.git
cd Ordo/app
flutter pub get
powershell -ExecutionPolicy Bypass -File windows\installer\build_installer.ps1
```

O script gera o app, coloca junto as DLLs do Visual C++ e cria o instalador em `app\build\installer\OrdoSetup-<versão>.exe`. Para só rodar sem instalar, use `flutter build windows --release` e abra `app\build\windows\x64\runner\Release\task_manager.exe`. Mais detalhes estão em [docs/distribuicao.md](docs/distribuicao.md).

---

## Instalar no Android

Funciona no Android 7.0 ou mais novo.

### Baixar e instalar (jeito fácil)

1. **No celular**, abra a página de [**Releases**](https://github.com/FLucasF/Ordo/releases/latest) e toque em **`Ordo-1.7.0.apk`** para baixar.
2. Quando terminar, toque na notificação do download, ou abra o app **Arquivos → Downloads** e toque no arquivo.
3. O Android avisa que, por segurança, o app de onde você está instalando (Chrome ou Arquivos) não pode instalar apps. Toque em **Configurações**, ligue **Permitir desta fonte** e volte.
4. Toque em **Instalar** e depois em **Abrir**.
5. Na primeira abertura, toque em **Permitir** para as notificações. Para os lembretes tocarem na hora exata, ative também *Configurações do Android → Apps → Ordo → Alarmes e lembretes*.

Se aparecer um aviso do **Play Protect** ("app desconhecido"), toque em **Mais detalhes → Instalar mesmo assim**. O aviso aparece porque o app não vem da Play Store.

- **Atualizar:** baixe o APK da versão nova e instale por cima. Seus dados continuam.
- **Desinstalar:** no Android, desinstalar **apaga os dados** do app. Antes, faça um backup (veja [Backup](#backup-e-troca-de-aparelho)).

> **Aparelhos autorizados (Android):** este app está registrado no Google numa conta de *distribuição limitada*. A partir de 30/09/2026, no Brasil, **só os celulares autorizados pelo dono do app** (até 20) conseguem instalar e atualizar. Para autorizar um celular, o dono gera um QR code ou um link no Android Developer Console. A pessoa abre no celular, aceita e manda de volta o código que aparece. Se quiser usar o app, peça esse link.

### Gerar a partir do código (para quem quer mexer no app)

O que precisa:

- Tudo da seção do Windows, menos o Visual Studio.
- [Android Studio](https://developer.android.com/studio), que traz o Android SDK. Depois de instalar, rode `flutter doctor --android-licenses` e aceite as licenças.

Para assinar com a sua chave, crie-a uma vez e aponte o projeto para ela, conforme o [docs/distribuicao.md](docs/distribuicao.md#android-apk). Sem ela, o APK sai com a chave de teste, que só serve para experimentar. A chave e a senha ficam fora do repositório (`key.properties` e `*.jks` estão no `.gitignore`).

```bash
cd Ordo/app
flutter build apk --release
```

O APK sai em `app/build/app/outputs/flutter-apk/app-release.apk`. Com `--split-per-abi` saem arquivos menores, um por tipo de processador; o `app-arm64-v8a-release.apk` serve para quase todos os celulares atuais. Para instalar pelo cabo, ative a **Depuração USB**, tocando 7 vezes em *Sobre o telefone → Número da versão* para liberar as *Opções do desenvolvedor*, e rode:

```bash
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

---

## Primeiros passos

- A tela inicial é **Hoje**. No Windows, a **barra de ícones** à esquerda leva aos módulos (Tarefas, Calendário, Matriz, Hábitos, Contagem, Foco, Finanças, Dieta, Diário, Estatísticas) e a **barra lateral** mostra smart lists, listas, áreas, filtros e etiquetas. No celular, tudo fica na gaveta **☰**.
- **Criar:** em cada tela, o botão azul no canto de cima diz o que cria (**+ Nova tarefa**, **+ Novo lançamento**, **+ Novo hábito**…). No celular é o **+** redondo embaixo.
- **Editar e apagar qualquer coisa:** tudo o que você adiciona tem o **⋯** na própria linha (ou botão direito), com Editar e Deletar. Ao abrir para editar, o formulário tem a **lixeira** vermelha. Apagar mostra **Desfazer** por alguns segundos; o que não dá para desfazer pede confirmação.
- **Desfazer e refazer:** `Ctrl+Z` e `Ctrl+Shift+Z` (ou `Ctrl+Y`) desfazem e refazem as últimas ações.
- **Ligar e desligar módulos:** *Configurações → Funcionalidades* esconde os módulos que você não usa.

---

## Todas as funcionalidades

### Tarefas e listas

- **Listas** com nome, **ícone** (emoji), **cor**, tipo (**tarefas** ou **notas**), modo de visualização e opção de aparecer ou não nas smart lists. Podem ser **fixadas**, **arquivadas** (vão para "Listas Arquivadas") e **duplicadas**.
- **Áreas** (pastas): agrupam listas na barra lateral, com ícone, cor e fundo próprios. Crie com o botão de área ao lado do **+** de "Listas"; arraste listas para dentro e para fora. Apagar uma área não apaga as listas, só as tira dela. Abrir a área mostra as tarefas de todas as listas dela.
- **Sublistas** (até 3 níveis, ex.: Faculdade → Cálculo → Lista 3): crie pelo **⋯ → Adicionar sublista**, pelo campo **Dentro de** do formulário ou arrastando uma lista para o meio de outra. Ficam recuadas sob a lista-mãe, com setinha para recolher. Na lista-mãe, **⋯ → Incluir sublistas** mostra também as tarefas delas, agrupadas por sublista. Ao apagar ou arquivar uma lista com sublistas, você escolhe se elas sobem um nível ou vão junto.
- **Seções** dentro da lista (adicionar, renomear, mover, inserir acima/abaixo, à esquerda/direita no Kanban), com "Não Classificado" para o resto.
- **Tarefas**, **subtarefas** (até 5 níveis), **checklists** (itens com caixinha, cada um com data/lembrete próprios) e **notas** (que não têm caixinha; tarefa ↔ nota converte num clique).
- **Prioridade** (alta, média, baixa, nenhuma), **datas** com ou sem hora, **duração** (início e fim), **fuso horário** fixo ou flutuante, **fixar** no topo, **Não farei** (vai para "Não será feito"), **duplicar**, **copiar link**, **mover para** outra lista (inclusive sublistas e seções), **vincular tarefa-pai**, **cor da tarefa** (usada no Calendário).
- **Ordem:** arraste para cima ou para baixo: a metade de cima de uma linha põe antes dela, a de baixo põe depois. Para virar **subtarefa**, arraste bem para a direita ou segure **Shift** ao soltar (aparece "Soltar como subtarefa"). No celular, segure e arraste; segurar e soltar sem mover abre o menu. Numa lista ordenada por data ou prioridade (como Hoje), arrastar passa a ordem para **Personalizado**, e isso fica salvo.
- **Ordenar e agrupar** (botão ⇅): agrupar por lista, data, prioridade, etiqueta ou sem grupo; ordenar por data, prioridade, título, criação, modificação ou personalizado; mostrar ou esconder concluídas e detalhes.
- **Lixeira:** apagadas ficam lá até você restaurar ou excluir de vez; **Esvaziar lixeira** apaga todas.
- **Atividades:** o histórico de cada tarefa e de cada lista (criada, concluída, data mudada, movida…).
- **Modelos de tarefa:** salve uma tarefa como modelo (conteúdo, checklist, etiquetas) e crie novas a partir dele. Já vêm prontos "Tarefas antes do trabalho", "Daily record", "Coisas para embalar para viajar", "Revisão Semanal", "Nota de leitura" e "Nota de Reunião".
- **Tarefas sugeridas** em Hoje (💡): atrasadas, próximas e sem data, com **+** para trazer para hoje.

### Adição rápida

Escreva tudo no título e o app entende:

| Você escreve | O que acontece |
|---|---|
| `Ligar para o dentista amanhã às 9h` | data amanhã, 9:00 |
| `Relatório sexta` · `Pagar luz 25/09` · `em 3 dias` · `próxima segunda` | datas |
| `Comprar pão !alta` | prioridade alta (`!média`, `!baixa`, `!nenhuma`) |
| `Estudar #faculdade` | etiqueta "faculdade" (cria se não existir) |
| `Reunião ~Trabalho` | vai para a lista "Trabalho" |

- O que foi reconhecido aparece destacado e pode ser **removido do título** (opção em *Configurações → Mais configurações → Reconhecimento Inteligente*).
- Um título que é só um **link** vira o título da página (opção "Análise de URL").
- **Shift+Enter** adiciona uma descrição. No Windows, a tecla **N** abre a adição rápida de qualquer tela; o botão de estilo alterna entre **Simples** e **Detalhado** (com data, prioridade, lista e etiquetas à mostra).

### Detalhe da tarefa

- No computador, abre no **painel lateral** ou numa **janela pop-up** (escolha no **…** da lista → Layout de detalhes). No celular, em tela cheia: concluir pela caixinha **fecha a tela**, com **Desfazer**.
- **Conteúdo** com editor completo:
  - `/` abre o menu: títulos 1 a 3, lista com marcadores, lista numerada, item de verificação, citação, linha horizontal, anexo, tarefa vinculada, subtarefa, etiqueta e modelo;
  - `[[` vincula outra tarefa ou nota (o vínculo abre num pop-up);
  - o botão **A** mostra a **barra de formatação** (título, negrito, itálico, sublinhado, tachado, hora, link, código);
  - **Escrita imersiva** esconde o resto da tela para escrever.
- **Anexos:** **… → Carregar anexo**, ou **arraste arquivos** do Explorador (Windows). **Imagens aparecem na própria tarefa** como prévia; clicar abre em tela cheia, com zoom (Esc fecha). O **⋯** do anexo tem abrir no app do sistema, baixar e deletar.
- **Rodapé:** o nome da lista (clique para mover), **+ Etiqueta**, **+ Subtarefa**, a barra de formatação (**A**), comentários e o **⋯**. As etiquetas da tarefa aparecem embaixo do texto (clique para editar) e as subtarefas logo abaixo.
- A **caixa de texto** é grande desde o começo e cresce com o que você escreve; clicar no espaço vazio leva o cursor para o fim do texto, e a tela acompanha enquanto você digita.
- **Comentários** com texto, emojis e imagens.
- **Informações** de uma nota: palavras, caracteres, criada e modificada.
- **Exportar** em Markdown ou texto puro, **copiar** e **imprimir**.

### Lembretes e repetição

- **Lembretes:** na hora, 5 ou 30 minutos antes, 1 hora antes, 1 dia antes, no dia às 9h, 1/2/3 dias ou 1 semana antes às 9h, no fim, ou personalizado. Vários por tarefa.
- Os avisos chegam **com o app fechado**, com os botões **Concluído** e **Adiar 15 min**. Com o app aberto, aparece um pop-up com **Adiar** (15 min, 30 min, 1h, 3h, hoje à noite, amanhã, personalizado), **Concluído** e **Dispensar**.
- **Lembrete constante:** a notificação fica até você agir. **Notificações diárias:** um resumo por dia, no horário que você escolher, com as tarefas de hoje.
- **Repetição:** diária, semanal, mensal, anual, dias úteis ou **Personalizado**: a cada N dias/semanas/meses/anos, com os **dias da semana em botões** (e atalhos "Dias úteis", "Fim de semana", "Todos"), "no dia N", "na primeira/última sexta", "primeiro/último dia útil", **datas específicas** escolhidas no calendário, e **pular fins de semana**. Repete **pela data de vencimento** ou **pela data de conclusão**. Termina nunca, numa data ou depois de N vezes.

### Visualizações

- **Lista** (com seções e grupos), **Kanban** (colunas por seção, arraste os cartões entre elas) e **Linha do tempo** (barras na régua de datas; o painel "Organizar tarefas" traz as sem data para arrastar). Teclas `V` → `L`/`K`/`T`.
- **Mostrar data por:** a data ou uma contagem ("em 3 dias").

### Smart lists, filtros e etiquetas

- **Smart lists:** Todas, Hoje, Amanhã, Próximos 7 dias, Caixa de Entrada, Resumo, Concluído, Não será feito e Lixeira. Em *Configurações → Lista inteligente* cada uma pode ser mostrada, escondida ou mostrada só quando tem tarefas.
- **Filtros personalizados:** modo **Normal** (listas, etiquetas, data, prioridade, tipo, palavra-chave) ou **Avançado** (condições com E/OU, "é"/"não é"), com **prévia** da quantidade. Na Busca, **Salvar como filtro**.
- **Etiquetas** com cor e **subetiquetas**; **mesclar** etiquetas (as tarefas de uma passam para a outra). Também aparecem como filtro na barra lateral.

### Seleção em lote

Selecione várias tarefas (Ctrl/Shift + clique no PC; no celular, segure → **Selecionar**) e aplique de uma vez: data, **atrasar** (1 dia, 1 semana ou N dias), prioridade, lista, etiquetas, concluir, fixar, Não farei, vincular tarefa-pai, **mesclar** (viram subtarefas de uma nova), duplicar, converter em nota, **copiar texto** e deletar.

### Calendário

- Visualizações **Dia**, **Semana**, **Vários dias**, **Várias semanas**, **Mês**, **Ano** e **Agenda**, nos estilos **Moderno** ou **Clássico**.
- **Criar e mover:** clique num horário para o cartão de criar (com **Mais opções** para a página completa); arraste para criar com duração, mover ou esticar; **Ctrl/Alt** ao arrastar copia. Ao mover aparece **Salvo** com **Desfazer** (tecla `Z`). Em tarefas que se repetem, editar, mover ou apagar pergunta: **Somente esta**, **Esta e as seguintes** ou **Todas**.
- **Popup de detalhes** ao clicar; o botão direito tem abrir, concluir, duplicar, deletar e cores.
- **Cores e rótulos:** escolha a cor da tarefa (arco-íris **+** para qualquer cor) e dê nome às cores no ✎ ("Faculdade", "Academia").
- **Insights de tempo:** horas do período por rótulo, lista, etiqueta ou tipo, e horas por dia.
- **Painel da esquerda:** mini calendário, **listas como calendários** (caixa para mostrar/esconder), outros calendários e "Organizar tarefas" para arrastar as sem data.
- **Mostrar ou esconder:** concluídas, itens de checklist, ciclos futuros das repetições, **hábitos**, **registros de foco**, **contagens regressivas**, **finanças** (contas, faturas e cobranças; clicar num item de Finanças oferece "Abrir em Finanças" ou "Novo lançamento neste dia"), fins de semana, ícones; escurecer eventos passados; esconder horas antes/depois de um horário; eventos curtos com tamanho de 30 minutos; **fusos adicionais** ao lado das horas; números da semana.
- **Calendários assinados:** **Feriados do Brasil** (calculados no aparelho) e qualquer calendário **.ics** por URL, atualizados sozinhos.
- **Atalhos do Google Agenda:** `D` `W` `M` `X` `A` `Y` mudam a visualização, `J`/`K` avançam e voltam, `T` vai para hoje, `C` cria, `G` vai para uma data; Shift + roda muda as datas e Ctrl + roda dá zoom nas horas.

### Matriz de Eisenhower

- Quatro quadrantes (urgente/importante). Arraste tarefas entre eles.
- **Editar Matriz:** nome, **emoji** e regras de cada quadrante (prioridades, datas, listas, etiquetas), com exemplos prontos ("Só prioridade", "Tempo + prioridade"); trocar quadrantes de lugar.
- Agrupar e ordenar dentro de cada quadrante; esconder concluídas.

### Foco (Pomodoro)

- **Pomo** (Pomodoro) ou **Cronômetro**, com ou sem tarefa ou hábito vinculado. Pausar, continuar, ±5 minutos, **tempo extra**, terminar.
- **Configurações de foco:** duração do Pomo, das pausas curta e longa, Pomos até a pausa longa, início automático do próximo Pomo ou da pausa, **som** (despertador, padrão, lembrete, mensagem, silencioso) e **tempo de execução no título da janela**.
- **Temporizadores** salvos (nome, modo e duração) como atalhos, com estatísticas próprias.
- **Estimativa** de Pomos ou duração por tarefa, e quanto já foi focado nela.
- **Registros:** visão geral (hoje e total), registros com notas, adicionar à mão, editar, **gestão em lote** (filtros por data, duração e vínculo; apagar vários) e **exportar**.
- O aviso de fim chega com o app fechado; no Android, a contagem fica numa notificação. Fechar o app não perde o Pomo em andamento.

### Hábitos

- Crie da **galeria** (Vida, Saúde, Exercício, Mente: 60 prontos) ou do zero, com **ícone** (emoji), **cor**, frase motivacional, frequência (diária, X vezes por semana, a cada N dias), meta (**conquistar tudo** ou **uma quantidade**, com unidade e passo), modo de marcar (automático, manual, completar tudo), data de início, dias de meta, **seção** (manhã, tarde, noite, outros ou uma sua), **etiquetas** (as mesmas das tarefas, mostradas ao lado dos totais) e lembretes.
- Marque o dia no círculo; um dia já marcado abre o menu (desfazer, pular, não alcançado, registrar como foi, com humor e nota).
- **Detalhe:** registros do mês, total de check-ins, taxa mensal, sequência atual, **mapa do ano**, log com os pensamentos de cada check-in.
- **Arraste** pela alça (⠿) para mudar a ordem dentro da seção (na visão em lista, sem filtro de dia nem ordenação por status).
- Mostrar em "Hoje" e "Próximos 7 dias" (lá, só o círculo marca; tocar no nome não sai da lista), ordenar por status, visão em cartão ou lista, arquivar, **exportar** (CSV).
- **Hábito em destaque no menu:** no celular, é o primeiro botão da gaveta ☰, com o progresso do dia ("4 de 12 hoje"); no Windows, o ícone fica sempre colorido na barra.

### Contagem regressiva e painel do projeto

- Tipos: **Contagem regressiva**, **Data especial**, **Aniversário** (com idade) e **Feriado**. Contagem para baixo ou para cima (cronômetro), modo de cálculo (o dia 1 começa no dia seguinte ou no próprio dia), ignorar o ano, repetir, lembretes.
- **Seguir a sequência de um hábito** (ou de uma seção inteira de hábitos): em vez de uma data, escolha a **meta de dias seguidos** (7, 21, 30, 60, 90, 100, 365 ou outra). O cartão mostra quantos dias faltam e "12 de 30 dias seguidos"; se a sequência quebra, a contagem volta. Numa seção, o dia conta quando todos os hábitos pedidos naquele dia foram feitos.
- **Cartões** em 6 estilos, com cor, **ícone** (emoji, texto ou ícone pronto) e **imagem de fundo**. Aparecem nas smart lists no dia, 3 ou 7 dias antes, sempre ou nunca. Fixar, arquivar, agrupar por tipo.
- **Vincular a uma lista ou área** transforma a contagem num **painel do projeto**:
  - dias restantes, **progresso** (feitas/total) e barra no cartão;
  - tarefas por seção, próximos prazos e as atrasadas;
  - gráfico de **evolução** (concluídas por dia);
  - **taxa de exatidão**: concluída no prazo = 100%, depois do prazo = 50%, vencida sem concluir = 0% (tarefas sem prazo ou com prazo futuro não contam);
  - **ritmo**: "faça 2,3 tarefas por dia", comparado com a média dos últimos 7 dias (verde, amarelo ou vermelho);
  - **Encerrar projeto** (ou automaticamente no dia seguinte à data) congela o **relatório final** com **troféus** ("Tudo concluído", "Tudo no prazo", "Reta final forte", "Sem atrasos 7 dias"), resumo de prazos, exatidão, evolução e melhor dia. Dá para rever depois e reabrir o projeto.

### Finanças

Valores em reais. As partes ficam nas **abas** do topo; o painel da esquerda escolhe o mês e mostra os gastos do mês.

- **Lançamentos:** receitas e despesas com valor, data, descrição, categoria, cartão e observação. Veja por mês, ano ou período; filtre por categoria, tipo ou palavra. O **+** ao lado de cada dia cria um lançamento naquela data. **Arraste** pela alça (⠿) para mudar a ordem dos lançamentos do mesmo dia (sem filtros ligados). As caixinhas aparecem como "Guardado"/"Retirado", sem contar como gasto.
- **Categorias:** as prontas (Alimentação, Mercado, Transporte, Moradia, Contas da casa, Saúde, Educação, Lazer, Compras, Assinaturas, Salário, Renda extra, Outros) e as suas, com **ícone**, cor e **limite por mês** (aviso a partir de 80%). Arraste para mudar a ordem.
- **Cartões:** fechamento e vencimento, limite e quanto está disponível, **fatura de cada mês** (aberta, fechada, paga ou vencida), compras **parceladas** distribuídas nas faturas seguintes, **Pagar fatura** (em partes também; o pagamento não conta como gasto de novo). A compra conta no mês da fatura. Arquivar cartões.
- **Contas fixas:** aluguel, internet, assinaturas, salário, mensais ou anuais, com início, fim e lembrete. Atrasadas e vencimentos do mês aparecem em destaque; **Pagar** (ou **Receber**) vira lançamento, e dá para desfazer.
- **Empréstimos:** quem pegou, valor emprestado, data, vencimento e juros (em % ou pelo total a receber). **À vista ou parcelado** (2 a 60 parcelas mensais, valor calculado ou digitado). Cada parcela tem status (paga, em aberto, atrasada), lembrete e **Receber parcela** com 1 toque; pagamentos a mais ou adiantados abatem as próximas. O app mostra lucro, recebido, saldo e se está **em dia, atrasado ou quitado**; filtre por situação e agrupe por mês do vencimento ou do empréstimo.
- **Caixinhas:** metas de dinheiro guardado (viagem, reserva…) com nome, **ícone**, cor, meta e data-alvo. Barra de progresso, quanto falta e **quanto guardar por mês** para chegar na data. **Guardar** e **Retirar** não contam como receita nem despesa. Arquivar e restaurar.
- **Relatórios:** gastos por categoria (rosca); **receitas × despesas** dos últimos 6 meses em **Geral** ou **Detalhado** (por categoria), com os **juros dos empréstimos** como parte separada; saldo dos meses; **comparação entre dois meses** por categoria; resumo dos empréstimos; total guardado nas caixinhas.
- Contas, faturas, cobranças de empréstimo e parcelas aparecem no **Calendário**, no **widget** e nos **lembretes**.

### Dieta

Diário do que você comeu, com a **Tabela TACO** (NEPA/Unicamp, 4ª edição: 597 alimentos, valores por 100 g).

- **Diário** do dia (‹ › e "Hoje" mudam o dia):
  - **+ Adicionar alimento:** escolha a refeição, busque sem precisar de acento ("feijao" acha "Feijão") e diga a quantidade em **gramas** ou numa **medida caseira** ("colher de sopa cheia", "unidade"…); a conta aparece na hora;
  - **Não achei:** cadastre um alimento seu ali mesmo e ele já entra na refeição;
  - **Totais do dia:** rosca de proteínas, carboidratos e gorduras com as calorias no centro, e o total de cada refeição; com **metas**, cada valor ganha **barra** "consumido / meta" (verde perto da meta, vermelha acima de 110%);
  - **Importar plano do dia** preenche o dia com o cardápio, com 1 toque (sem duplicar);
  - **Adesão do dia** em %.
- **Refeições:** as 6 de sempre (Café da manhã, Lanche da manhã, Almoço, Lanche da tarde, Jantar, Ceia) e **as suas**, com **nome e horário**. O horário define a refeição sugerida. **+ Refeição**; ⋯ para editar, mover, arquivar ou deletar.
- **Alimentos:** os seus (calorias, proteínas, carboidratos, gorduras e fibras por 100 g; **calorias em branco são calculadas pelos macros**: P×4 + C×4 + G×9) e a busca na TACO. **Medidas caseiras**: quantas quiser, nos seus alimentos e também nos da TACO.
- **Metas** (⚙): calorias, proteínas, carboidratos e gorduras, com opção de calcular as calorias pelos macros.
- **Plano** (aba): o cardápio base refeição por refeição, com variações por **dia da semana**, total do plano do dia.
- **Adesão:** por item do plano (como planejado = 100%, quantidade ou alimento trocado = 50%, pulado = 0%) combinada com a meta de calorias; média da semana e do mês e **calendário de calor**.

### Diário

- **Dia:** **humor** (5 rostos), **energia** (1 a 5), **meta principal de amanhã** e **notas do dia** com o mesmo editor das tarefas (formatação, imagens, anexos, vínculos `[[`). Tudo salva sozinho. ‹ ›, "Hoje" e calendário para trocar de dia; a lixeira apaga a entrada (com Desfazer).
- **Resumo do dia** automático: tarefas concluídas, hábitos feitos, calorias (contra a meta, se houver), minutos de foco e **finanças** (entrou, saiu e saldo do dia; aparece sempre que Finanças está ligada). Cada linha abre o módulo dela.
- No Windows, a página do dia tem **barra de rolagem** sempre visível, e a caixa de notas cresce com o texto.
- **Linha do tempo:** as entradas com humor, energia e trecho; **busca** por palavra (sem acento) e **filtros** por humor e energia.
- **Calendário:** cada dia colorido pelo humor, com **gráficos** de humor e energia no mês.

### Resumo

- Relatório editável do período (hoje, semana, mês, personalizado), filtrado por listas, status, etiquetas e prioridades.
- Agrupe por status, lista, data de conclusão, data da tarefa, etiqueta ou prioridade; escolha os campos (status, progresso, tempo de conclusão e da tarefa, tarefa-pai, etiqueta, lista, detalhes, dados de foco) e se mostra as tarefas do próximo período.
- **Modelos** de resumo; **copiar**, **salvar como PDF** ou **imagem**, **enviar por e-mail** ou **inserir numa nota**.

### Estatísticas

- **Visão geral:** tarefas, concluídas, listas e dias de uso; conclusão de hoje e total; **pontuação de conquista** com níveis; **medalhas** (Perseverança, Res perfice, Atenção plena, Autodisciplina).
- **Tarefas:** concluídas por dia, semana ou mês; taxa de conclusão; no prazo, atrasadas e não concluídas; por lista, etiqueta, prioridade e tarefa.
- **Foco:** curvas de Pomos e duração, detalhes, tendências, linha do tempo da semana, horários mais concentrados e grade anual.
- **Hábitos:** status semanal.

### Busca, paleta e atalhos

- **Busca** (`/`): tarefas, notas, etiquetas e listas, com filtros (listas, etiqueta, data, prioridade, tipo, status), busca nas listas arquivadas e **Salvar como filtro**.
- **Paleta de comandos** (`Ctrl+K`): ir para qualquer lista, área, módulo ou ação.
- **Atalhos de teclado** (Windows): `?` mostra todos; em *Configurações → Atalhos* dá para **trocar as teclas** (inclusive sequências como `G` → `T`).

### Ícones (emojis)

- O seletor tem **todos os 3.773 emojis do Unicode** (até a versão 15.1, com todos os tons de pele), em 8 abas (Pessoas e Corpo, Natureza, Comida, Atividades, Viagem, Objetos, Símbolos, Bandeiras), com **busca em português** ("joinha", "cachorro", "cafe", "envergonhado"…) e aceita **colar um emoji**. **Aleatório** escolhe um; **Redefinir** tira o ícone.
- Onde escolher: **listas**, **áreas**, **hábitos**, **contagens**, **categorias** e **caixinhas** das Finanças, quadrantes da **Matriz** e **comentários**.
- O desenho é o do sistema (Windows ou Android). No Windows, as **bandeiras** aparecem como letras do país, porque a fonte do Windows não tem o desenho delas.

### Aparência e idioma

- **Idioma:** Português ou Latina (*Configurações → Aparência → Idioma*). Os textos do próprio sistema (copiar, colar, seletores) ficam em português.
- **Tema** claro, escuro ou seguindo o sistema; **11 séries de cores** e **cor personalizada**; estilo da interface **Plano** ou **Cartão**.
- **Temas prontos:** Padrão, Estudos, Trabalho, Noite, Natureza, Praia e Aconchego (cores, fundo e estilo de uma vez; tudo continua editável).
- **Papel de parede:** 8 degradês (Amanhecer, Pôr do sol, Oceano, Floresta, Lavanda, Noite, Pêssego, Menta) ou uma **imagem sua**, com controle para **escurecer/clarear** e prévia ao vivo. Aparece atrás das listas, do Calendário e dos módulos.
- **Fundo por lista e por área:** a lista usa o dela, senão o da lista-mãe, senão o da área, senão o do app ("Nenhum" deixa a lista lisa).
- **Exibição:** contagem na barra lateral, **cor da lista** como faixa nas tarefas, estilo das concluídas (padrão ou riscado), mini calendário na barra lateral.

### Widget de calendário (Android)

Segure um espaço vazio da tela inicial → **Widgets** → **Ordo → Calendário**.

- Escolha **Dia**, **Semana** ou **Mês** no próprio widget (cada widget guarda a sua escolha); **‹ ›** avançam e voltam, o título volta para hoje, o **+** cria uma tarefa e tocar num dia abre o app nele.
- No modo **Dia**, cada compromisso fica tão alto quanto dura (um das 8h às 12h vira um bloco com início e fim): pequeno, o widget é uma lista; aumentando, os blocos crescem e ocupam o espaço todo. Quando o dia não cabe, a lista **rola** (Android 12 ou mais novo; antes disso, o que não cabe vira "+N").
- Mostra também contas, faturas e parcelas das Finanças, conforme as opções do Calendário.

### Mini calendário (Windows)

Ligue em *Configurações → Notificações → **Mini calendário*** (interruptor), ou clique com o botão direito no ícone do Ordo perto do relógio → **Mini calendário**.

- Uma janelinha com o calendário na área de trabalho, igual ao widget do celular: **Dia**, **Semana** ou **Mês**, **‹ ›**, **+**, e clique num compromisso para abrir o app nele.
- Arraste pelo título e redimensione pelas bordas.
- O **📌** escolhe se ela fica **por cima das janelas**, **normal** ou **na área de trabalho** (atrás das janelas; aparece com Win + D).
- Ela lembra o lugar, o tamanho e o modo. Ligada, volta aberta toda vez que o Ordo inicia; o **×** (ou desligar o interruptor) fecha e ela não volta.

### Segundo plano, notificações e sons

- **Windows:** fechar a janela deixa o Ordo na **bandeja**, perto do relógio. Lembretes, Pomodoro e mini calendário continuam; clique no ícone para abrir, ou botão direito → **Sair** para fechar de vez. Em *Configurações → Notificações*: **Manter na bandeja ao fechar** e **Iniciar com o Windows** (abre escondido na bandeja).
- **Som:** lembretes e fim do Pomo tocam um **despertador**. Em *Configurações → Notificações → Som do lembrete* (e em *Foco → Configurações de foco → Som do Pomo*) troque por Padrão ou Silencioso. No Windows, o despertador do Pomo toca até você tocar no app ou clicar em **Parar** no aviso.
- **Android:** para lembretes na hora exata, ative *Alarmes e lembretes* nas configurações do Android para o Ordo.

### Configurações

Abra pelo avatar (canto superior esquerdo) → **Configurações**. As abas:

- **Conta:** conta local; **Sincronizar aparelhos**; **Gerar Backup** e **Importar backups locais**; **Backups automáticos** com **Restaurar**; **Exportar para Excel** e **Importar do Excel**.
- **Funcionalidades:** ligar e desligar Calendário, Matriz, Hábitos (e suas configurações), Foco, Contagem regressiva, Finanças, Dieta e Diário.
- **Lista inteligente:** mostrar, esconder ou mostrar só se não estiver vazia, para cada smart list, Etiquetas e Filtros.
- **Notificações:** notificações diárias e horário, lembrete constante, som do lembrete, bandeja, iniciar com o Windows e o interruptor do mini calendário.
- **Data e hora:** formato de data (31/12/2026, 12/31/2026 ou 2026/12/31), 24 ou 12 horas, início da semana, números da semana, escolher fuso ao definir a hora.
- **Aparência:** idioma, estilo da interface, tema, cores, temas prontos, papel de parede, contagem na barra lateral, cor da lista, estilo das concluídas.
- **Mais configurações:** reconhecimento inteligente (datas, remover o texto reconhecido, etiquetas, links); padrões de tarefa (data, lembretes com hora e de dia inteiro, duração, prioridade, etiqueta, lista, posição de novas tarefas e da seção "Atrasadas"); mini calendário na barra lateral; modelos de tarefa.
- **Integrações e Importação:** backup do TickTick (.csv), arquivos iCal (.ics) e calendários assinados (Feriados do Brasil e por URL).
- **Atalhos:** a lista completa, com as teclas editáveis.
- **Sobre:** versão do app.

---

## Backup e troca de aparelho

- **Configurações → Conta → Gerar Backup** salva um `.zip` com tudo, inclusive anexos e imagens. Em **Importar backups locais**, esse arquivo substitui os dados do aparelho (o app pede confirmação).
- **Backups automáticos:** o app faz sozinho uma cópia por dia, sem os anexos, e guarda as 7 mais recentes. Elas ficam listadas em *Configurações → Conta → Backups automáticos*, com o botão **Restaurar**.
- **Excel:** *Configurações → Conta → Exportar para Excel* gera uma planilha com uma aba por módulo (Tarefas, Hábitos, Lançamentos, Cartões, Faturas pagas, Empréstimos, Recebimentos, Caixinhas, Movimentações, Dieta, Diário), com datas e valores em reais formatados. **Importar do Excel** traz **tarefas e lançamentos** (da planilha exportada ou de uma sua com as mesmas colunas), mostra uma **prévia** com os erros antes, **só acrescenta** e faz uma cópia de segurança antes.
- **Sincronia automática (pelo Wi-Fi):** ligue o celular e o PC uma vez, e eles ficam iguais sozinhos.
  1. Abra o Ordo nos dois, no mesmo Wi-Fi. Num deles, toque no avatar → **Sincronizar aparelhos** → **Ligar a outro aparelho** e escolha o outro na lista (ou digite o endereço dele).
  2. Os **dois mostram um número de 6 dígitos**. Confira se é o mesmo e toque em **Ligar** nos dois.
  3. Pronto. A partir daí, sempre que os dois estiverem no mesmo Wi-Fi com o Ordo aberto, eles trocam as mudanças: ao abrir o app, alguns segundos depois de cada alteração e a cada 2 minutos. No PC, o Ordo continua rodando perto do relógio, então o celular sincroniza com ele sempre que você abre o app.

  **Nada se perde:** as mudanças dos dois lados são **juntadas**. Se o mesmo item foi alterado nos dois, vale a alteração mais recente; uma exclusão também viaja (a não ser que o item tenha sido editado do outro lado depois). Se os dois escreveram no Diário no mesmo dia, as notas ficam juntas. Anexos, imagens das contagens e fundos vão junto. Preferências do aparelho (tamanho da janela, mini calendário, papel de parede, iniciar com o Windows) não viajam.

  **Seguro:** a ligação combina uma chave secreta entre os dois (o número conferido nas duas telas impede que um terceiro se meta no meio), e cada sincronia é **criptografada** com ela. Nada passa pela internet. O ícone de nuvem na barra (PC) ou no topo da gaveta (celular) mostra o estado; em **Sincronizar aparelhos** dá para **Sincronizar agora** ou **Desligar** um aparelho. Os relógios dos dois precisam estar certos (o app avisa se estiverem diferentes). Redes de visitante ou de empresa às vezes bloqueiam a conversa entre aparelhos; o Wi-Fi de casa e o roteador do celular funcionam.

  Se os aparelhos começaram separados, com as mesmas coisas cadastradas nos dois, faça antes uma **cópia completa** (abaixo) para nada aparecer em dobro.
- **Cópia completa (uma vez):** toque no avatar → **Sincronizar aparelhos** (ou *Configurações → Conta*), na parte de baixo.
  1. No aparelho que vai **ficar igual ao outro**, toque em **Receber neste aparelho**. Aparece um código de 6 números.
  2. No aparelho que **tem os dados certos**, toque em **Enviar deste aparelho**, escolha o outro na lista e digite o código.
  3. Pronto: tudo (tarefas, hábitos, finanças, dieta, diário, anexos, configurações) vai de um para o outro. Antes de trocar, quem recebe guarda uma cópia dos próprios dados, que aparece com a hora em *Backups automáticos*, para desfazer.

  Os dois precisam estar no **mesmo Wi-Fi**, com o app aberto e **na mesma versão**. Não usa internet nem conta: os dados vão direto de um aparelho para o outro pela rede de casa, sem criptografia, então use em redes de confiança (não em Wi-Fi público). É uma cópia completa, não uma junção: use como fonte o aparelho onde você mexeu por último. Para o dia a dia, prefira a sincronia automática. No Windows, na primeira vez que receber, o Firewall pergunta; clique em **Permitir acesso**. Se um não achar o outro, use **Digitar endereço** com o endereço que aparece na tela de quem recebe.
- **Por arquivo:** gere o backup num aparelho, copie o `.zip` e importe no outro.
- **Vindo do TickTick:** lá, gere o backup em *Configurações → Conta → Backup & Recuperação*. Aqui, importe em *Configurações → Integrações e Importação → Backup do TickTick (.csv)*. Traz pastas, listas, seções, etiquetas, subtarefas, checklists e concluídas.

---

## Para desenvolver

O código fica em `app/` (Flutter + Riverpod + go_router, banco SQLite via Drift).

```bash
cd app
flutter pub get
flutter test                                              # todos os testes
flutter run -d windows                                    # rodar no Windows
dart run build_runner build --delete-conflicting-outputs  # depois de mudar o banco
flutter gen-l10n                                          # depois de mudar os textos (lib/l10n/app_pt.arb e app_la.arb)
```

- **Idiomas:** o código, os comentários e o banco são em inglês. O texto da tela fica em `lib/l10n/app_pt.arb` (português) e `lib/l10n/app_la.arb` (latim); um teste confere que os dois têm as mesmas chaves.
- **Rodar ao lado do app instalado:** uma versão de desenvolvimento com a variável `TAREFAS_DATA_DIR` usa outra pasta de dados, outra chave de registro e não mexe nas notificações nem no "Iniciar com o Windows" do app instalado.
- **Emojis:** `tool/make_emoji_asset.py` gera `lib/features/common/emoji_data.dart` a partir dos dados oficiais do Unicode (emoji-test.txt e as anotações em português do CLDR).
- **Tabela TACO:** `tool/make_taco_asset.py` gera `assets/taco.json`.
- **Versões novas:** [docs/distribuicao.md](docs/distribuicao.md) explica como gerar o instalador e o APK.
- **Ícone:** a imagem fica em `app/tool/icon_source.png` e os tamanhos de Windows e Android saem de `app/tool/make_icons.py`. Para trocar, rode `python tool/make_icons.py caminho/da/imagem.png` com o ícone pronto em fundo branco: o branco em volta é recortado.

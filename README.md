# Tarefas

App pessoal de tarefas e produtividade para **Windows** e **Android**, com o jeito de usar do TickTick: listas, calendário, matriz de Eisenhower, Pomodoro, hábitos, contagem regressiva, resumo e estatísticas.

Os dados ficam **só no seu aparelho**: não tem conta, login nem servidor. Para levar os dados de um aparelho para outro, use o backup (veja [Backup](#backup-e-troca-de-aparelho)).

> Projeto pessoal e independente, sem ligação com o TickTick nem com a Appest. Nome e código são próprios; só o fluxo de uso foi inspirado no app original.

## O que tem

- **Tarefas:** listas, pastas, seções, etiquetas, subtarefas, checklists e notas. Também prioridade, datas com hora, duração, repetição (inclusive "pular fins de semana"), lembretes, anexos, comentários e fuso horário.
- **Adição rápida:** escreva a data em português ("amanhã às 15h", "sexta", "25/09"), `!alta`, `#etiqueta` e `~Lista` no próprio título.
- **Smart lists:** Hoje, Amanhã, Próximos 7 dias, Todas, Caixa de Entrada, Resumo, Concluído, Não será feito e Lixeira. Há ainda filtros personalizados.
- **Visualizações:** Lista, Kanban e Linha do tempo. O Calendário tem dia, semana, vários dias, mês, ano e agenda.
- **Outras telas:**
  - Matriz de Eisenhower;
  - Foco (Pomodoro e cronômetro), com registros e estatísticas;
  - Hábitos, com metas e histórico;
  - Contagem regressiva (datas especiais, aniversários, feriados);
  - Finanças: receitas e despesas, categorias com limite, cartão de crédito com faturas e parcelas, contas fixas, empréstimos e relatórios;
  - Resumo com modelos e exportação;
  - Calendários assinados (.ics), com os feriados do Brasil já prontos.
- **Conteúdo das tarefas:** editor com títulos, listas, checklist, citação, código, links e vínculo entre tarefas (`[[`). Tem menu `/` e escrita imersiva.
- **Backup:** backup manual (com anexos), backup automático diário e importação do TickTick (CSV) e de arquivos iCal.
- **Atalhos de teclado no Windows:** aperte `?` no app para ver todos.

---

## Instalar no Windows

### Baixar e instalar (jeito fácil)

1. Abra a página de [**Releases**](https://github.com/FLucasF/toDO-manager/releases/latest) e baixe o **`TarefasSetup-1.2.1.exe`**.
2. Dê dois cliques no arquivo baixado.
3. O Windows pode mostrar o aviso azul do **SmartScreen** ("O Windows protegeu o computador"), porque o instalador não tem assinatura digital paga. Clique em **Mais informações → Executar assim mesmo**.
4. Siga o instalador: **Avançar → Instalar → Concluir**. Ele não pede senha de administrador e cria o atalho **Tarefas** no menu Iniciar. Se você marcar a opção, cria também na área de trabalho.

Funciona no Windows 10 e 11 (64 bits). Não precisa instalar mais nada, porque o instalador já leva tudo o que o app usa.

> **Erro "desktop_drop_plugin.dll não foi projetado para ser executado no Windows" (0xc0e90002):** é o **Controle Inteligente de Aplicativos** do Windows 11 bloqueando o app, porque os arquivos dele não têm assinatura digital paga (o arquivo não está estragado). Para usar, desligue essa proteção em *Segurança do Windows → Controle de aplicativos e navegador → Configurações do Controle Inteligente de Aplicativos*. Atenção: em muitas versões do Windows 11, depois de desligada ela só volta reinstalando o Windows.

- **Atualizar:** baixe o instalador da versão nova e rode por cima, mesmo com o app aberto na bandeja (o instalador fecha o app sozinho). Suas tarefas continuam.
- **Desinstalar:** use *Configurações do Windows → Aplicativos → Tarefas → Desinstalar*. Seus dados **não** são apagados; se instalar de novo, eles voltam.

### Onde ficam os dados

Os dados ficam em `%APPDATA%\dev.lucasfelipe\Tarefas`: o banco de dados, os anexos e os backups automáticos. Para apagar tudo de vez, apague essa pasta depois de desinstalar.

### Gerar a partir do código (para quem quer mexer no app)

O que precisa:

- [Git](https://git-scm.com/download/win).
- [Flutter](https://docs.flutter.dev/get-started/install/windows/desktop) 3.47 ou mais novo.
- [Visual Studio 2022](https://visualstudio.microsoft.com/pt-br/downloads/) (a edição Community é gratuita), com a carga de trabalho **"Desenvolvimento para desktop com C++"**. Confira com `flutter doctor`.
- Para gerar o instalador, o [Inno Setup 6](https://jrsoftware.org/isinfo.php), que é gratuito: `winget install JRSoftware.InnoSetup`.

```bash
git clone https://github.com/FLucasF/toDO-manager.git
cd toDO-manager/app
flutter pub get
powershell -ExecutionPolicy Bypass -File windows\installer\build_installer.ps1
```

O script gera o app, coloca junto as DLLs do Visual C++ e cria o instalador em `app\build\installer\TarefasSetup-<versão>.exe`. Para só rodar sem instalar, use `flutter build windows --release` e abra `app\build\windows\x64\runner\Release\task_manager.exe`. Mais detalhes estão em [docs/distribuicao.md](docs/distribuicao.md).

---

## Instalar no Android

Funciona no Android 7.0 ou mais novo.

### Baixar e instalar (jeito fácil)

1. **No celular**, abra a página de [**Releases**](https://github.com/FLucasF/toDO-manager/releases/latest) e toque em **`Tarefas-1.2.1.apk`** para baixar.
2. Quando terminar, toque na notificação do download, ou abra o app **Arquivos → Downloads** e toque no arquivo.
3. O Android avisa que, por segurança, o app de onde você está instalando (Chrome ou Arquivos) não pode instalar apps. Toque em **Configurações**, ligue **Permitir desta fonte** e volte.
4. Toque em **Instalar** e depois em **Abrir**.
5. Na primeira abertura, toque em **Permitir** para as notificações. Para os lembretes tocarem na hora exata, ative também *Configurações do Android → Apps → Tarefas → Alarmes e lembretes*.

Se aparecer um aviso do **Play Protect** ("app desconhecido"), toque em **Mais detalhes → Instalar mesmo assim**. O aviso aparece porque o app não vem da Play Store.

- **Atualizar:** baixe o APK da versão nova e instale por cima. Suas tarefas continuam.
- **Desinstalar:** no Android, desinstalar **apaga os dados** do app. Antes, faça um backup (veja [Backup](#backup-e-troca-de-aparelho)).

> **Aparelhos autorizados (Android):** este app está registrado no Google numa conta de *distribuição limitada*. A partir de 30/09/2026, no Brasil, **só os celulares autorizados pelo dono do app** (até 20) conseguem instalar e atualizar. Para autorizar um celular, o dono gera um QR code ou um link no Android Developer Console. A pessoa abre no celular, aceita e manda de volta o código que aparece. Se quiser usar o app, peça esse link.

### Gerar a partir do código (para quem quer mexer no app)

O que precisa:

- Tudo da seção do Windows, menos o Visual Studio.
- [Android Studio](https://developer.android.com/studio), que traz o Android SDK. Depois de instalar, rode `flutter doctor --android-licenses` e aceite as licenças.

Para assinar com a sua chave, crie-a uma vez e aponte o projeto para ela, conforme o [docs/distribuicao.md](docs/distribuicao.md#android-apk). Sem ela, o APK sai com a chave de teste, que só serve para experimentar. A chave e a senha ficam fora do repositório (`key.properties` e `*.jks` estão no `.gitignore`).

```bash
cd toDO-manager/app
flutter build apk --release
```

O APK sai em `app/build/app/outputs/flutter-apk/app-release.apk`. Com `--split-per-abi` saem arquivos menores, um por tipo de processador; o `app-arm64-v8a-release.apk` serve para quase todos os celulares atuais. Para instalar pelo cabo, ative a **Depuração USB**, tocando 7 vezes em *Sobre o telefone → Número da versão* para liberar as *Opções do desenvolvedor*, e rode:

```bash
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

---

## Como usar

### Primeiros passos

- A tela inicial é **Hoje**. No Windows, a barra lateral mostra smart lists, listas, filtros e etiquetas. No celular elas ficam na gaveta **☰**, junto com Calendário, Matriz, Hábitos, Contagem Regressiva, Foco e Finanças. No celular também há Kanban, e segurar uma tarefa mostra **Selecionar** para editar várias de uma vez.
- Para **criar uma lista**, use o **+** ao lado de "Listas". Nela você escolhe a cor, o ícone, a pasta e se é lista de tarefas ou de notas.
- Para **adicionar uma tarefa**, escreva no campo do topo da lista e aperte Enter. No Windows, a tecla `N` abre a adição rápida de qualquer lugar.
- **Abrir, concluir e organizar:** clique numa tarefa para abrir o detalhe; a caixinha conclui. O botão direito (ou o **…**) abre o menu: data, prioridade, mover, etiquetas, foco, duplicar, converter em nota…
- **Editar e apagar qualquer coisa:** tudo o que você adiciona (lançamentos, contas, hábitos, contagens, listas, etiquetas, filtros…) tem o **⋯** na própria linha, com Editar e Deletar. Ao abrir para editar, o formulário tem a **lixeira** vermelha. O que não dá para desfazer pede confirmação antes.
- **Criar:** em cada tela, o botão azul no canto de cima diz o que cria (**+ Novo lançamento**, **+ Novo hábito**, **+ Nova tarefa**…). No celular é o **+** redondo embaixo.

### Adição rápida

Escreva tudo no título, e o app entende:

| Você escreve | O que acontece |
|---|---|
| `Ligar para o dentista amanhã às 9h` | data amanhã, 9:00 |
| `Relatório sexta` · `Pagar luz 25/09` · `em 3 dias` | datas |
| `Comprar pão !alta` | prioridade alta (`!média`, `!baixa`, `!nenhuma`) |
| `Estudar #faculdade` | etiqueta "faculdade" (cria se não existir) |
| `Reunião ~Trabalho` | vai para a lista "Trabalho" |

### No detalhe da tarefa

- **Conteúdo:**
  - digite `/` para o menu: título, lista, checklist, anexo, modelo, subtarefa…;
  - digite `[[` para vincular outra tarefa;
  - o botão **A** no rodapé mostra a barra de formatação.
- **Anexos:** use **… → Carregar anexo**. No Windows, dá para **arrastar arquivos** do Explorador para o detalhe.
- **Outros recursos:** data, lembretes e repetição ficam no topo; subtarefas e comentários, embaixo.

### Telas principais

- **Calendário:**
  - arraste para criar ou mover;
  - use Ctrl/Alt ao arrastar para copiar;
  - Shift + roda do mouse muda as datas, e Ctrl + roda dá zoom nas horas.
  - no estilo do Google Agenda: clique num horário para abrir o cartão de criar, e use **Mais opções** para a página completa (repetições como "Mensal na última sexta", lembretes, prioridade);
  - o painel da esquerda (☰) tem o mini calendário e as listas como calendários, com caixa de seleção para mostrar ou esconder cada uma;
  - clique numa tarefa para ver o **popup de detalhes** (editar, apagar, concluir e mais opções no ⋮); o botão direito tem abrir, concluir, duplicar, deletar e as cores;
  - ao mover ou esticar uma tarefa aparece **Salvo** com **Desfazer** (a tecla `Z` também desfaz);
  - numa tarefa que se repete, editar, apagar ou mover pergunta: **Somente esta**, **Esta e as seguintes** ou **Todas**;
  - **cores e rótulos:** clique com o botão direito numa tarefa do calendário (ou use **Cor da tarefa** no ⋯ da tarefa) para escolher a cor. O arco-íris **+** abre a paleta para qualquer cor. No ✎ você dá nome às cores, como "Faculdade" ou "Academia";
  - **Insights de tempo:** a barra mostra as horas do período por rótulo (passe o mouse para ver cada um); **Mais insights** abre a rosca por rótulo, lista, etiqueta ou tipo, e as horas de cada dia. No celular, fica no **⋯** do topo;
  - **Repetição personalizada:** em **Mais opções**, escolha "Personalizado…" para repetir a cada N dias, semanas, meses ou anos, e terminar numa data ou depois de N vezes;
  - teclas do Google: `D` `W` `M` `X` `A` `Y` mudam a visualização, `J`/`K` avançam e voltam, `T` vai para hoje, `C` cria e `G` vai para uma data.
- **Matriz:** as tarefas se dividem por urgência e importância. Arraste entre os quadrantes, e use o **…** do topo para editar as regras.
- **Foco:** Pomodoro ou cronômetro, com ou sem tarefa vinculada. Os registros aparecem na própria tela e nas Estatísticas. O aviso de fim do Pomo e da pausa chega mesmo com o app fechado, com som de **despertador** (troque em **… → Configurações de foco → Som do Pomo**). Fechar o app não perde o Pomo em andamento.
- **Hábitos:** marque o dia no círculo; clicar num dia já marcado abre o menu para desfazer ou registrar como foi. Ao criar, escolha na galeria ou crie o seu, com meta, frequência, lembrete e **cor** (o botão ao lado do nome abre as mesmas cores do Calendário, com o arco-íris para qualquer cor; o botão direito → **Cor** troca na hora).
- **Contagem regressiva:** para contagens, datas especiais, aniversários e feriados, agrupadas por tipo. Os **Tipos** do painel da esquerda mostram ou escondem cada um.
- **Finanças** (valores em reais). As partes ficam nas **abas** do topo:
  - **Lançamentos:** receitas e despesas com valor, data, descrição, categoria e cartão. Veja por mês, ano ou período, filtre por categoria, tipo ou palavra;
  - **Categorias:** as prontas e as suas, com **limite por mês**; o app avisa a partir de 80% do limite;
  - **Cartões:** dia de fechamento e de vencimento, fatura de cada mês (aberta, fechada, paga ou vencida), compras **parceladas** distribuídas nas faturas seguintes e **Pagar fatura** (o pagamento não conta como gasto de novo). A compra conta no mês da fatura;
  - **Contas fixas:** aluguel, assinaturas, salário, mensais ou anuais, com lembrete. Ao **Pagar** (ou **Receber**), vira lançamento;
  - **Empréstimos:** quem pegou, valor, data, vencimento e juros (em % ou pelo total a receber); o app mostra o lucro, os pagamentos (inclusive parciais), o saldo e se está em dia, atrasado ou quitado, e avisa no vencimento e no atraso;
  - **Relatórios:** gastos por categoria, receitas × despesas dos últimos meses, comparação entre dois meses e o resumo dos empréstimos.
- **Resumo:** um relatório do período que pode ser editado. Dá para copiar, salvar em PDF ou imagem, mandar por e-mail ou inserir numa nota.
- **Busca:** tecla `/`. A paleta de comandos é `Ctrl+K`, e `?` mostra todos os atalhos. As teclas podem ser mudadas em Configurações → Atalhos.

### Segundo plano e sons

- **Windows:** fechar a janela deixa o Tarefas na **bandeja**, perto do relógio. Os lembretes e o Pomodoro continuam; clique no ícone para abrir, ou use o botão direito → **Sair** para fechar de vez. Em Configurações → Notificações dá para desligar isso e ligar **Iniciar com o Windows**.
- **Som:** lembretes e fim do Pomo tocam um **despertador**. Em Configurações → Notificações → **Som do lembrete** (e em Foco → Configurações de foco → **Som do Pomo**) dá para trocar por Padrão ou Silencioso. No Windows, o despertador do Pomo toca até você tocar no app ou clicar em **Parar** no aviso.

### Configurações

Abra pelo avatar (canto superior esquerdo) → **Configurações**. As abas:

- **Conta:** backup.
- **Funcionalidades:** módulos e smart lists visíveis.
- **Aparência:** tema e cores.
- **Mais configurações:** início da semana, formato de data, fuso horário, lembretes padrão etc.
- **Modelos de tarefa**, **Atalhos** e **Integrações e Importação**.

A duração e o som do Pomodoro ficam no **…** da tela Foco.

### Backup e troca de aparelho

- **Configurações → Conta → Gerar Backup** salva um `.zip` com tudo, inclusive anexos. Em **Importar backups locais**, esse arquivo substitui os dados do aparelho (o app pede confirmação).
- **Backups automáticos:** o app faz sozinho uma cópia por dia, sem os anexos, e guarda as 7 mais recentes. Elas ficam listadas em Configurações → Conta → Backups automáticos, com o botão **Restaurar**.
- **Deixar o celular e o PC iguais (pelo Wi-Fi):** toque no avatar → **Sincronizar aparelhos** (ou *Configurações → Conta*).
  1. No aparelho que vai **ficar igual ao outro**, toque em **Receber neste aparelho**. Aparece um código de 6 números.
  2. No aparelho que **tem os dados certos**, toque em **Enviar deste aparelho**, escolha o outro na lista e digite o código.
  3. Pronto: tudo (tarefas, hábitos, finanças, anexos, configurações) vai de um para o outro. Antes de trocar, quem recebe guarda uma cópia dos próprios dados, que aparece com a hora em *Backups automáticos*, para desfazer.

  Os dois precisam estar no **mesmo Wi-Fi**, com o app aberto e **na mesma versão**. Não usa internet nem conta: os dados vão direto de um aparelho para o outro pela rede de casa, sem criptografia, então use em redes de confiança (não em Wi-Fi público). É uma cópia completa, não uma junção: use como fonte o aparelho onde você mexeu por último. No Windows, na primeira vez que receber, o Firewall pergunta; clique em **Permitir acesso**. Se um não achar o outro, use **Digitar endereço** com o endereço que aparece na tela de quem recebe.
- **Por arquivo:** gere o backup num aparelho, copie o `.zip` e importe no outro.
- **Vindo do TickTick:** lá, gere o backup em *Configurações → Conta → Backup & Recuperação*. Aqui, importe em *Configurações → Integrações e Importação → Backup do TickTick (.csv)*.

---

## Para desenvolver

O código fica em `app/` (Flutter + Riverpod + go_router, banco SQLite via Drift).

```bash
cd app
flutter pub get
flutter test                                              # todos os testes
flutter run -d windows                                    # rodar no Windows
dart run build_runner build --delete-conflicting-outputs  # depois de mudar o banco
flutter gen-l10n                                          # depois de mudar os textos (lib/l10n/app_pt.arb)
```

- **Idiomas:** o código, os comentários e o banco são em inglês. Só o texto da tela é em português, via `lib/l10n/app_pt.arb`.
- **Versões novas:** [docs/distribuicao.md](docs/distribuicao.md) explica como gerar o instalador e o APK.
- **Ícone:** a imagem fica em `app/tool/icon_source.png` e os tamanhos de Windows e Android saem de `app/tool/make_icons.py`. Para trocar, rode `python tool/make_icons.py caminho/da/imagem.png` com o ícone pronto em fundo branco: o branco em volta é recortado.

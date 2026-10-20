# Como gerar os instaladores (Fase 8)

Tudo aqui roda no seu computador. Nenhuma chave nem senha foi criada por mim: a chave de assinatura do Android é sua e fica fora do repositório.

## Android (APK)

### 1. Criar a chave de assinatura (uma vez só)

No terminal (o `keytool` vem com o Java do Android Studio / do Flutter):

```
keytool -genkey -v -keystore J:\chaves\tarefas.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tarefas
```

Ele pede uma senha e alguns dados (nome etc.). **Guarde o arquivo `.jks` e a senha em dois lugares** (por exemplo, num pendrive e no seu gerenciador de senhas). Sem eles, não dá para instalar uma versão nova por cima: seria preciso desinstalar, o que apaga os dados do app.

### 2. Apontar o projeto para a chave

Crie o arquivo `app/android/key.properties` (ele já está no `.gitignore`, não vai para o Git):

```
storeFile=J:/chaves/tarefas.jks
storePassword=SUA_SENHA
keyAlias=tarefas
keyPassword=SUA_SENHA
```

Sem esse arquivo, o build de release usa a chave de teste (debug). Serve para experimentar, mas não para o uso de verdade.

### 3. Gerar o APK

```
cd app
flutter build apk --release
```

O arquivo sai em `app/build/app/outputs/flutter-apk/app-release.apk`.

Esse APK tem cerca de 80 MB porque leva o app para todos os tipos de processador. Para arquivos menores (uns 25 MB), use `flutter build apk --release --split-per-abi` e instale o `app-arm64-v8a-release.apk`, que serve para quase todos os celulares atuais.

### 4. Instalar no celular

- Copie o APK para o celular e abra (o Android pede para permitir a instalação de "fontes desconhecidas"), ou
- com o celular ligado por USB e a depuração ativada: `adb install -r app-release.apk`.

A partir de 30/09/2026, o Android no Brasil passa a exigir desenvolvedor verificado para apps instalados fora da loja. O app já está registrado:

- **Conta:** distribuição limitada no [Android Developer Console](https://android.google.com/developerconsole).
- **Pacote:** `dev.lucasfelipe.task_manager`, com a impressão SHA-256 da chave `tarefas` (**Verificado**).

Para cada celular que vai usar o app (até 20), abra **Dispositivos**, dê um nome e gere o código:
- **Com o celular na mão:** leia o QR code com a câmera dele.
- **Para outra pessoa:** mande o link, que vale 7 dias.

Depois digite o código que aparece no celular e clique em **Adicionar dispositivo**. Celulares não autorizados não instalam nem atualizam o app. Remover um aparelho não tem volta.

Se um dia trocar de chave, adicione a nova impressão digital em **Nomes de pacote → dev.lucasfelipe.task_manager → Adicionar chave**.

### 5. Atualizar

Instale o APK novo por cima: com a mesma chave, os dados continuam. **Atenção:** a versão de teste (debug, a que usamos no emulador) e a de release têm chaves diferentes. Para trocar de uma para a outra é preciso desinstalar, o que apaga os dados. Antes, faça um backup em Configurações → Conta → Gerar Backup e depois importe.

## Windows (instalador .exe)

### Gerar o instalador

Precisa do [Inno Setup 6](https://jrsoftware.org/isinfo.php), que é gratuito (`winget install JRSoftware.InnoSetup`), e do Visual Studio 2022 com C++, que o Flutter já pede. Na pasta `app`:

```
powershell -ExecutionPolicy Bypass -File windows\installer\build_installer.ps1
```

O script faz tudo:

1. `flutter build windows --release`;
2. copia as DLLs do Visual C++ (`msvcp140`, `vcruntime140`, `vcruntime140_1`), tiradas da pasta de redistribuíveis do Visual Studio, para junto do app, e assim ele abre num Windows que não tenha esse pacote;
3. compila `windows\installer\tarefas.iss`.

O instalador sai em `app/build/installer/OrdoSetup-1.0.0.exe`.

Ele instala só para o seu usuário (sem pedir administrador), em `%LOCALAPPDATA%\Programs\Tarefas`. Também cria o atalho no menu Iniciar (e na área de trabalho, se você marcar).

Na primeira execução o Windows pode mostrar o aviso do SmartScreen: clique em **Mais informações → Executar assim mesmo**. Isso acontece porque o instalador não tem assinatura digital paga.

### Publicar para os usuários

Crie uma versão em **Releases** no GitHub e anexe o `OrdoSetup-<versão>.exe`. Pelo terminal:

```
gh release create v1.1.0 app/build/installer/OrdoSetup-1.1.0.exe Ordo-1.1.0.apk --title "Ordo 1.1.0" --notes "O que mudou…"
```

### 3. Atualizar

Rode o instalador da versão nova por cima. Os dados ficam na pasta do usuário (AppData) e não são apagados, nem ao desinstalar.

## Mudar a versão

Mude `version:` em `app/pubspec.yaml` (ex.: `1.0.1+2`), `#define AppVersion` em `app/windows/installer/tarefas.iss` e `appVersion` em `app/lib/features/settings/settings_dialog.dart` (a versão que aparece em Configurações). O número depois do `+` precisa subir a cada APK novo.

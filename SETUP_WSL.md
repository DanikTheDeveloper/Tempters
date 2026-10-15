# TEMPTERS — установка и запуск в WSL2 / Debian 13

Используем установленный в WSL **Godot Standard** и **GDScript**, не .NET. Godot должен быть доступен из того же Linux-терминала, что и Codex. Не переустанавливай Node.js, Git и Godot, если они уже работают.

## 1. Проверить инструменты

```bash
cat /etc/os-release | head
command -v godot && godot --version
command -v codex && codex --version
git --version
```

Если `godot` есть, этого достаточно для начала. В случае ошибки с окном сначала проверь WSLg; headless-проверки могут работать даже без GUI.

## 2. Создать единственную папку проекта

```bash
mkdir -p ~/projects/Tempters
cd ~/projects/Tempters
explorer.exe .
```

Помести скачанный **Tempters.zip** в открытую папку. Затем:

```bash
cd ~/projects/Tempters
unzip -o Tempters.zip
ls -l AGENTS.md PROMPTS/01_START_FRESH.md
```

ZIP содержит документы **прямо в корне архива** — дополнительной вложенной папки не появится. После распаковки должен существовать файл `~/projects/Tempters/AGENTS.md`. Игра в ZIP не включена: Codex создаст `project.godot` и все сцены при первом запуске.

## 3. Запустить Codex

```bash
cd ~/projects/Tempters
codex
```

Введи:

```text
Read PROMPTS/01_START_FRESH.md and execute it completely. Start coding immediately.
```

Не используй `sudo codex`. Codex должен работать с файлами пользователя в WSL, а не с корневым каталогом Windows.

## 4. Открыть готовую игру

Когда Codex создаст `project.godot`:

```bash
cd ~/projects/Tempters
godot --headless --path . --editor --import --quit
godot --editor --path .
```

В редакторе F5 — запуск игры. Для базовой автоматической проверки:

```bash
godot --headless --path . --quit-after 60
```

Графический Godot работает через WSLg. Если есть проблемы с драйвером/рендерером, начни с Compatibility; если Godot GUI в WSLg недоступен, пользуйся headless проверкой в Linux и при необходимости Windows Godot GUI по `\\wsl.localhost\<DistroName>\home\<user>\projects\Tempters` — это запасной путь, не обязательный шаг.

## 5. Ресурсы и настройки

- Для работы в WSL хранить исходники в `~/projects/Tempters`, а не `/mnt/c`, удобнее и обычно быстрее.
- 2.5D — настоящая 3D-сцена, поэтому нужны GPU/WSLg и подходящий драйвер. Совместимость зависит от конфигурации машины.
- Codex-конфиг лежит в `~/.codex/config.toml`. `CODEX_CONFIG.example.toml` — только образец, существующие настройки не перезаписывать.
- На базовых задачах ориентируйся на Medium reasoning; переключай уровень только при сложных проблемах. Фактические модели и лимиты смотрятся в самом Codex.
- Для контроля окна использования пользуйся `/status`.
- Git: после первого успешно проверенного этапа выполни `git init` (если репозитория ещё нет), `git add .` и `git commit -m "W1 playable baseline"`. Никогда не коммить пароли, токены и кэши.

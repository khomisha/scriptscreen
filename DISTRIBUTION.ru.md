# ScriptScreen — Руководство по дистрибутиву

**web/Electron**-дистрибутив ScriptScreen для Linux, Windows и macOS. (Нативная
сборка Flutter `io` считается устаревшей и постепенно выводится из использования.)

Дистрибутив — это обычный архив: пользователь распаковывает его и запускает один
установочный скрипт. Платформенного инсталлятора/MSI нет, и в Windows **никакие
ключи реестра для самого ScriptScreen не создаются**.

Эта страница — указатель. Полная документация находится в каталоге `dist/`:

| Документ | Для кого | Содержание |
|----------|----------|------------|
| [dist/README.md](dist/README.md) | Мейнтейнер | Сборка архивов дистрибутива через `make-dist.sh`; структура архива. |
| [dist/vendor/README.md](dist/vendor/README.md) | Мейнтейнер | Куда класть готовые сборки whisper.cpp + ffmpeg (модели речи в архив не включаются — их скачивает инсталлятор). |
| [dist/BUILD_WHISPER.md](dist/BUILD_WHISPER.md) | Мейнтейнер | Сборка бинарников `whisper-cli` / `whisper-stream` на каждой ОС. |
| [dist/templates/common/INSTALL.md](dist/templates/common/INSTALL.md) | Пользователь | Установка и удаление приложения (также входит в каждый архив). |

> 🇬🇧 English version: [DISTRIBUTION.md](DISTRIBUTION.md)

## Быстрый старт (мейнтейнер)

```bash
# 1. Соберите whisper.cpp + ffmpeg и поместите их в dist/vendor/<платформа>/
#    (см. dist/BUILD_WHISPER.md и dist/vendor/README.md)
# 2. Соберите архив:
dist/make-dist.sh --platform linux        # или windows | macos
# -> dist/out/scriptscreen-<версия>-<платформа>.{tar.gz|zip}
```

# Music

Плеер лайков Яндекс Музыки (yandex-music-cli) поверх MPD. Воспроизведение —
общий `plugins/mpd/MpdService.qml` (его же использует Radio).

**Бар:** `Исполнитель - Трек` (без иконки), когда играют лайки, иначе серое
`Music` с иконкой.
Клик — попап, средняя кнопка — play/pause (или запуск лайков),
колесо — следующий/предыдущий трек. Попап растёт вправо от плашки. С клавиатуры: `qs -c taskbar ipc call music toggle`.

## Попап

- **Шапка:** `Music`, `PLAYING · 3 / 256` / `PAUSED · …` / `OFF`, тумблер —
  играть лайки (продолжить или `music --init`) / остановить.
- **Вкладки** `Now playing` и `Queue (N)`.
- **Now playing:** обложка (встроенная в mp3, кэш `~/.cache/quickshell/music`),
  трек, исполнитель, альбом · год; сердечко — лайк/снятие лайка в Яндексе
  (снятый удаляется из библиотеки при следующем обновлении). Таймлайн с
  перемоткой (отправляется, когда отпускаешь ползунок). Управление: shuffle,
  ⏮ ⏯ ⏭, повтор «выкл → вся очередь → один трек»; включённый режим — залитая
  кнопка.
- **Queue:** вся очередь, видно `Theme.musicUpNext` строк, сама прокручивается
  к текущему треку (серая заливка). Справа кнопки: обновить лайки
  (`music --update`) и поиск по очереди. Клик — играть.

## Файлы

| Файл | Что |
|---|---|
| `Music.qml` | Бар-модуль |
| `MusicService.qml` | Очередь, обложка, лайки, синхронизация |
| `MusicPopup.qml` | Попап |
| `MusicQueue.qml` | Очередь / поиск |
| `../mpd/MpdService.qml` | Общее состояние MPD и команды плеера |
| `scripts/music.sh` | `mpc`, `manager.py` yandex-music-cli, станции radio-cli |
| `scripts/yandex_likes.py` | Лайки через API `yandex-music` (uv, тот же `token`) |

## Скрипты

`music.sh`: `--status`, `--listen`, `--queue`, `--stations`, `--cover FILE`,
`--play [POS]`, `--stop`, `--toggle`, `--next`, `--prev`, `--seek SEC`,
`--random`, `--repeat`, `--radio KEY`, `--likes`, `--update`. Команды запуска
сами поднимают `mpd.service`.

`yandex_likes.py`: `--likes` (`{liked, files}`), `--like ID`, `--unlike ID`.

## Зависимости

`~/.config/scripts/yandex-music/` (manager.py, token, state.json). `music` в zsh —
функция, поэтому плагин вызывает `uv run --script manager.py` напрямую.

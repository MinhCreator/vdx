# Music

Плеер лайков Яндекс Музыки (yandex-music-cli) поверх MPD. Воспроизведение —
общий `plugins/mpd/MpdService.qml` (его же использует Radio).

**Бар:** `Исполнитель - Трек` (без иконки), когда играют лайки, иначе серое `♫ Music`.
Клик — попап, средняя кнопка — play/pause (или запуск лайков), правая — ncmpcpp,
колесо — следующий/предыдущий трек. Попап растёт вправо от плашки
(`alignLeft`). С клавиатуры: `qs -c taskbar ipc call music toggle`.

## Попап

- **Шапка:** `MUSIC` / `PLAYING · 3/256`, `PAUSED · …`, `OFF`. Кнопка UPDATE —
  синхронизировать лайки (`music --update`). Тумблер — играть лайки (продолжить
  или `music --init`) / остановить.
- **Карточка:** обложка (встроенная в mp3, кэш `~/.cache/quickshell/music`),
  трек, исполнитель, альбом · год; сердечко — лайк/снятие лайка в Яндексе
  (снятый удаляется из библиотеки при следующем UPDATE).
- **Прогресс** с перемоткой и время.
- **Управление:** случайный порядок (shuffle / shuffle_disabled), ⏮ ⏯ ⏭, повтор
  «выкл → вся очередь → один трек» (repeat_off / repeat / repeat_once).
  Включённый режим — зелёный.
- **QUEUE** — вся очередь (название, исполнитель, номер), видно
  `Theme.musicUpNext` строк. Сама прокручивается так, чтобы текущий трек (белая
  полоса) был сверху: выше — предыдущие, ниже — следующие. Лупа превращает
  список в поиск по всей очереди. Клик — играть.
- Перемотка отправляется, когда отпускаешь ползунок; пока тянешь — время
  показывает позицию под курсором.

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

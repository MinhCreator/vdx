# Claude

Лимиты тарифа и расход Claude Code.

**Бар:** иконка робота. Жёлтая, когда какой-то лимит ≥ `Theme.claudeWarning`
(75%), красная ≥ `Theme.claudeCritical` (90%). Клик открывает попап.

## Попап

- **Шапка:** `CLAUDE CODE` / `PRO · 1 WORKING` (`N IDLE`, `NO SESSIONS`).
  Кнопка справа — обновить всё.
- **Лимиты** — то же, что `/usage`: окно сессии (5 часов), неделя и другие, если
  они есть у тарифа. Полоска, процент и время до сброса.
- **TODAY** — токены за сегодня из локальных логов: output, input, cache
  read/write, число ответов.
- **SESSIONS** — запущенные Claude Code: имя, папка, версия, BUSY / IDLE.

## Как работает

- Лимиты: `claude.sh --usage` берёт OAuth-токен из `~/.claude/.credentials.json`
  и спрашивает `api.anthropic.com/api/oauth/usage` раз в
  `Theme.claudeUsageIntervalMs` (5 минут) и при открытии попапа. Токен уходит
  только на api.anthropic.com, передаётся через stdin (не виден в списке
  процессов) и не обновляется скриптом: истёк — «token expired», пока Claude Code
  не запустится снова. Эндпоинт недокументированный — может поменяться.
- TODAY: `claude.sh --today` суммирует `message.usage` ответов за сегодня из
  `~/.claude/projects/*/*.jsonl` (дубли одного ответа отбрасываются).
- SESSIONS: `~/.claude/sessions/*.json` с живым pid.
- Локальные данные обновляются раз в `Theme.claudeLocalIntervalMs`, пока попап
  открыт.

## Файлы

| Файл | Что |
|---|---|
| `Claude.qml` | Бар-модуль |
| `ClaudeService.qml` | Опросы и состояние |
| `ClaudePopup.qml` | Попап |
| `scripts/claude.sh` | `--usage`, `--today`, `--sessions` |

**IPC:** `qs -c taskbar ipc call claude toggle` — открыть/закрыть попап.

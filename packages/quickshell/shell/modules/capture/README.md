# capture

Камера в баре: клик открывает оверлей захвата (как Super+Shift+S). Во время
записи — красная точка и время; клик останавливает запись.

Сам захват — `apps/capture/` (`CaptureService`, `CaptureOverlay`,
`CaptureToolbar`, `CaptureRecording`): область / окно / экран, скриншот в
`~/Pictures/Screenshots` и буфер, запись через `gpu-screen-recorder` в
`~/Videos/Recordings`.

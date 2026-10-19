# 12 — Keyboard and assistive access

Status: Not started · Category: B/C · Depends on: nothing ·
Gate: one prototype popup approved before rollout. Spec: §13. Left over from
the product-wide UX audit (2026-10-19, finding U-05); the rest of that audit
is done (git history: `docs/implementation-plans/12_PRODUCT_WIDE_UX_AUDIT.md`).

## Finding

Settings and popups are mouse-only. Whole shell: `activeFocusOnTab` 1,
`KeyNavigation` 0, `Accessible.*` 0; focus visuals only in `kit/KitInput.qml`,
`kit/KitColourField.qml`; `KitSwitch` / `KitButton` are bare `MouseArea`s.
Escape works everywhere. Hypothesis: a popup opened by a key gets the keyboard
only after a click (`bar/Bar.qml` `OnDemand`).

Impact: no Tab / Enter / Space in Shell Manager or popups; no screen-reader
names (WCAG 2.2 SC 2.1.1, 2.4.7, 4.1.2).

## Scope

- Focus and keys in the Kit controls: Tab order, Space toggles, arrows in
  Choices, Enter activates.
- One visible focus token in `docs/shell/design.md`.
- `Accessible.name` / `role` on every Kit control.
- Prototype: the Wi-Fi popup; then the rest after approval.

Out: screen-reader testing beyond names and roles.

## Risk

Every Kit control changes; the focus ring is a visual change (owner approval;
refactors keep visuals).

## Acceptance

Wi-Fi popup and one Shell Manager page fully usable by keyboard; focus always
visible; `qs log` clean; mouse behaviour unchanged.

## Sources

WCAG 2.2, https://www.w3.org/TR/WCAG22/ — SC 2.1.1, 2.4.7, 4.1.2.

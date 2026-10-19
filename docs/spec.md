# Master Instructions for Claude Code: Shell Stabilization, UX Redesign, Applications, and Documentation

> **Purpose:** This document is the project-level instruction for Claude Code. It defines the goals, working method, scope, and required deliverables. It is **not** a request to implement every feature in one session. Your first responsibility is to inspect the repository, then break the work into small, self-contained phases with separate Markdown instructions that can be executed and reviewed independently.

## 1. Mission and Product Goals

We are developing a custom graphical Shell for Arch Linux. The project already contains a significant amount of work, including system modules, applications, settings, a bar, a hub, a lock screen, system integrations, and user-facing utilities.

This is not merely a personal configuration. The long-term goal is to build a coherent, reliable, extensible product that other people can install and customize for different hardware, displays, workflows, and preferences.

The main goals, in order of importance, are:

1. Predictable behavior and stability.
2. A cohesive, high-quality user interface and user experience (UI/UX).
3. Settings that are easy to understand and navigate.
4. Deep customization without contradictory options or broken combinations.
5. Clear boundaries between the Shell, applications, modules, and optional integrations.
6. Maintainable, consistent, and extensible code.
7. Reliable installation, upgrades, testing, and documentation.

Do not optimize exclusively for the current author's preferences. Consider the experience of a first-time user who does not know the project's internal architecture.

## 2. Non-Negotiable Working Principles

### 2.1 Inspect before changing

Before changing code, inspect the relevant implementation, its callers, dependencies, configuration, styles, state management, and related tests. For substantial changes, read the complete files being edited and understand their role in the wider architecture.

Do not claim to have audited the entire repository if only a subset was inspected. Record what was inspected and what remains unknown.

For every task, identify:

- The relevant files and components.
- The current behavior and intended behavior.
- The probable root cause or architectural issue.
- Related state, settings, events, and dependencies.
- Existing tests and available validation tools.
- Potential regressions and compatibility concerns.

### 2.2 Prefer root-cause fixes

Fix underlying causes rather than adding individual workarounds for visible symptoms. Avoid arbitrary delays, duplicate state stores, forced refreshes, suppressed errors, brittle device-name matching, hard-coded indexes, or other patches unless the design demonstrably requires them.

### 2.3 Preserve unrelated behavior

Make the smallest coherent change that solves the task. Do not refactor unrelated code, change public interfaces, remove existing functionality, or add dependencies without a documented reason.

When settings or persisted data change, preserve compatibility where possible. If migration is required, document and test it.

### 2.4 Follow the project's established conventions—unless an audit proves they should change

Study the existing structure, code style, naming, component patterns, design tokens, and test conventions. Preserve good existing patterns. If a convention is inconsistent or harmful, describe the issue and propose a deliberate correction rather than silently introducing another pattern.

### 2.5 Separate research, approval, implementation, and verification

Treat tasks in three categories:

- **Category A — Local fixes:** after inspecting the code and writing a short plan, implementation may proceed.
- **Category B — Medium functional changes:** audit the behavior, describe the UX and affected components, and seek approval when user behavior or architectural conventions will change materially.
- **Category C — Major redesigns and new applications:** research, architecture proposal, detailed plan, independent review, and owner approval are required before major implementation.

Category C includes the full Settings redesign, the camera architecture proposal, a new bar/notch mode, the music subsystem redesign, the torrent client, and a product-wide UX audit.

Do not implement every task in a single large change. Do not make approval-dependent decisions silently.

### 2.6 Report facts honestly

Do not claim a test, build, manual check, web research, or agent review was completed unless it actually was. Clearly distinguish verified results, unverified assumptions, proposals awaiting approval, and blocked work.

---

## 3. Your First Deliverable: A Staged Work Plan, Not a Code Change

**Initially, do not modify application code and do not start implementing the feature backlog.** Inspect the repository and produce a project plan.

The plan must split the work into phases that can be executed separately. Each phase must have its own Markdown instruction file with all information needed to perform that phase without interpreting the entire master document again.

### 3.1 Required planning outputs

Create or update the following documentation structure, adapting names and locations if the repository already has an equivalent structure:

```text
docs/
├── SHELL_PROJECT_ROADMAP.md
├── SHELL_ARCHITECTURE.md
├── SHELL_DEVELOPMENT_GUIDELINES.md
├── SHELL_DESIGN_SYSTEM.md
├── SHELL_TESTING_AND_RELEASE.md
├── decisions/
│   └── README.md
└── implementation-plans/
    ├── 00_REPOSITORY_AUDIT.md
    ├── 01_NOTIFICATION_SYSTEM.md
    ├── 02_FILEPICKER_AND_AUDIO_FIXES.md
    ├── 03_DISPLAY_AND_WALLPAPER_FIXES.md
    ├── 04_BLUETOOTH_LABEL_FIX.md
    ├── 05_SETTINGS_REDESIGN.md
    ├── 06_LOCKSCREEN_CUSTOMIZATION.md
    ├── 07_FILE_MANAGER_IMPROVEMENTS.md
    ├── 08_BAR_ISLAND_AND_NOTCH_MODE.md
    ├── 09_MUSIC_SUBSYSTEM.md
    ├── 10_TORRENT_CLIENT.md
    ├── 11_CAMERA_ARCHITECTURE.md
    ├── 12_PRODUCT_WIDE_UX_AUDIT.md
    └── 13_FINAL_INTEGRATION_AND_REVIEW.md
```

These are proposed names, not a command to create duplicate documents. First inspect the repository. Reuse and improve existing documents when appropriate. If there is already a task-management convention, follow it and explain any deviation from the structure above.

Not every file must be fully authored before the first report. However, the roadmap must show all known work, dependencies, recommended order, approval gates, and the expected documents. Each implementation-plan file must be completed before that phase begins.

### 3.2 What each phase instruction must contain

Every separate instruction file must be self-contained and include:

1. **Objective and context.** The user problem and desired outcome.
2. **Scope.** What is included and what is explicitly excluded.
3. **Initial investigation.** Files, components, integrations, or behavior to inspect; do not fabricate paths before repository discovery.
4. **Requirements.** Functional, UX, accessibility, architectural, and compatibility requirements as applicable.
5. **Constraints.** Project conventions, APIs, dependencies, and implementation boundaries.
6. **Dependencies.** Upstream work or decisions that must be completed first.
7. **Approval gate.** What must be submitted for review before implementation, if applicable.
8. **Agent delegation plan.** Which parts can be safely delegated, what each agent may edit, and what the primary agent must review. Use this only where it adds value.
9. **Implementation sequence.** Small, ordered steps.
10. **Acceptance criteria.** Observable conditions that establish completion.
11. **Validation.** Exact tests or commands after they have been confirmed to exist in the repository; manual scenarios where needed.
12. **Regression checklist.** Related behavior that must continue to work.
13. **Reporting format.** Files changed, root cause, decisions, tests, remaining risks, and unfinished work.

Use unambiguous instructions. Separate mandatory requirements from recommendations. Avoid vague requirements such as “make it beautiful” unless they are translated into inspectable design principles and acceptance criteria.

### 3.3 Dependencies and execution order

The roadmap must explain dependencies and identify tasks that can run in parallel. At minimum, consider this sequence:

1. Repository audit and inventory.
2. Small stability fixes: notifications, filepicker, audio device listing, display/wallpaper behavior, and Bluetooth label.
3. Product-wide architecture and UX audit.
4. Settings redesign research and proposal.
5. Unified development guidelines and design-system documentation; draft early, then refine using approved redesign decisions.
6. Settings redesign implementation.
7. Lock-screen customization.
8. File-manager improvements.
9. Bar/Island/Notch mode research and implementation.
10. Music subsystem research, architecture approval, and implementation.
11. Camera architecture research and proposal.
12. Torrent-client research, design, and implementation.
13. Integration, regression review, documentation reconciliation, and final report.

This is a starting point, not an inflexible order. Adjust it when repository evidence reveals dependencies. Document why the order changed. Do not start a feature whose architecture depends on an unapproved decision.

---

## 4. Repository Audit and Research Standards

### 4.1 Repository and architecture inventory

The initial audit must map, as far as the repository allows:

- Main application entry points and runtime architecture.
- Applications, system modules, reusable components, and system integrations.
- Bar, hub, Island, notification center, notifications, settings, lock screen, file manager, camera, audio, Bluetooth, displays, wallpaper handling, and music integration.
- Theme and design-token implementation.
- Configuration and settings persistence.
- Installer and dotfiles setup flow, including optional components.
- Service and process lifecycle.
- Test infrastructure, linting, formatting, type checking, builds, and packaging.
- Documentation and existing architectural decisions.

Produce a map of the relevant components and dependencies, not just a list of filenames.

### 4.2 External research

For UX, design, system behavior, and architecture questions, consult reliable and current sources when relevant. Potential reference points include:

- Noctalia Shell and other relevant Linux Shell projects.
- KDE Plasma and GNOME.
- Microsoft Windows and Fluent Design guidance.
- macOS, iOS, and Apple's Human Interface Guidelines.
- Android and Material Design guidance.
- Accessibility guidance and relevant engineering articles by experienced designers and developers.
- Official Linux/system API documentation for platform integrations.

Select sources based on the question rather than mechanically citing every product. Do not copy competitor interfaces literally. Distinguish official documentation from opinion pieces and your own inferences.

For each major recommendation, record the source, principle observed, applicability, limitations, and the design decision derived from it. Never invent sources or claim that a source recommends something it does not.

### 4.3 Honest evaluation

Be critical and specific. Identify confusing settings, overlapping responsibilities, inaccessible patterns, hidden dependencies, unnecessary complexity, weak error states, performance costs, and unsupported assumptions. Existing implementation is not proof that a design decision is good.

---

## 5. Existing Bug-Fix Backlog

These tasks should each have a bounded scope and independent acceptance criteria. Do not combine all fixes into a large refactor.

### 5.1 Notifications

#### A. Previously displayed notifications reappear

Observed scenario:
1. A notification arrives.
2. The user ignores it; it is displayed.
3. A second notification arrives.
4. Both the new notification and the earlier notification appear again.

Investigate notification identity, event handling, queueing, timers, overlay lifecycle, dismissal, and state synchronization.

Expected behavior:

- A new notification must not reactivate or duplicate a previously displayed toast without a new event.
- Each notification must have a predictable lifecycle.
- A dismissed or expired toast must not reappear merely because another notification arrived.
- A notification retained in the notification center may remain stored without being shown again as a toast.
- A single event must not create multiple visual instances of the same notification.

#### B. Clicking a notification opens the wrong UI

Observed behavior: clicking an incoming notification opens the notification center instead of the originating application.

Investigate click routing, event handlers, source identity, and supported notification actions. A click should activate the associated application or perform the source-provided action when that information is available. Do not route every click to the notification center. Handle notifications that do not provide an actionable target gracefully.

#### C. Inconsistent notification-center behavior

Define coherent behavior for arrival, toast display, manual dismissal, timeout, retention in the center, opening the center, opening the source application, deleting one item, clearing all items (if supported), and repeated notifications from the same source.

Keep the state of a toast separate from the persisted notification-center entry. Do not introduce a complex new state machine if the existing architecture can be fixed cleanly.

#### D. Toast duration setting

Add a user-facing setting for toast duration through the existing settings architecture. Offer a sensible finite set of durations. Consider a persistent option only if it is technically compatible and makes sense for accessibility and UX.

Manual dismissal must work independently of timeout. Expiration must not delete an entry retained in the notification center. Avoid timer leaks and repeated close operations. Apply changes to new notifications without restarting the Shell where feasible.

#### E. Screenshot and screen-recording notifications

Provide independent preferences to show or hide notifications about screenshots and screen recording. Disabling notifications must not disable screenshot or recording functionality, and must not affect unrelated notifications.

### 5.2 Filepicker shows stale files

Investigate data fetching, caching, navigation, list state, and filesystem change handling.

Expected behavior:

- Opening the filepicker shows the current contents of the selected directory.
- Navigating to another directory updates the list correctly.
- Changes made after the dialog was first opened do not remain indefinitely hidden by stale data.
- Returning to a directory follows a consistent cache-refresh strategy.
- Creation, deletion, and renaming are reflected using the chosen refresh mechanism.
- Refreshing does not create duplicate entries or unnecessary repeated requests.

Check filters, hidden files, and sorting for regressions. Do not introduce a permanent filesystem watcher unless repository evidence shows it is necessary.

### 5.3 Duplicate or inconsistent microphone entries

Observed behavior: the sound module shows two microphones even though no external device is connected. After choosing “Internal Microphone,” the second entry disappears.

Investigate the audio backend, device identifiers, aliases, source roles, default-device logic, event handling, and UI-state synchronization.

Expected behavior:

- The list accurately represents devices according to the intended product model.
- One physical device is not duplicated merely because the backend exposes multiple representations of it.
- The internal microphone remains selectable and is displayed consistently.
- Device connection and disconnection events update the list correctly.
- Choosing a device does not serve as a workaround that makes a duplicate disappear.

Do not deduplicate by a hard-coded index or fragile name matching. Establish the correct identity/role criteria before implementing a fix.

### 5.4 Wallpaper changes when using Displays

Observed behavior: while the desktop background is set to a solid color using the Theme mode, interacting with the Displays application changes it to the first wallpaper in the current theme.

Fix the behavior so display operations do not overwrite the selected background. Investigate the display configuration flow, theme application, wallpaper manager, and persisted user preference. Establish which component is the source of truth for the chosen background.

### 5.5 Incorrect wallpaper during Hyprland session startup

Observed behavior: after a Hyprland session starts, the first wallpaper from the current theme is visible for several seconds before the wallpaper configured in Shell settings appears.

Investigate process/service startup order, configuration loading, theme initialization, and wallpaper initialization. Remove the unwanted intermediate background. Do not use arbitrary sleep intervals as the primary fix.

### 5.6 Bluetooth button label

Change the Bluetooth module's “Scan” button label to “Rescan.” Check related localizations, identifiers, tests, and equivalent UI references where applicable. Do not change scan behavior unless investigation shows it is required.

---

## 6. Settings Redesign

This is a major product-level project, not a cosmetic restyle.

### Objective

Make Shell Settings understandable, cohesive, and efficient to navigate. Users should be able to find a setting without knowing the internal architecture. The current category structure must not be assumed correct simply because it already exists.

### Required audit

1. Inventory every section, subsection, setting, and nested option.
2. Record each setting's purpose, current location, dependencies, persistence behavior, and affected feature.
3. Identify duplicates, contradictions, unclear labels, unnecessary options, hidden dependencies, and inconsistent controls.
4. Reassess how system settings, appearance, personalization, behavior, applications, modules, and integrations should be grouped.
5. Design a new information architecture.
6. Test whether representative tasks are easy to find without prior knowledge of the Shell.
7. Establish a consistent system for buttons, switches, tabs, sliders, selectors, fields, descriptions, grouped sections, dialogs, and secondary options.
8. Remove visual clutter caused by inconsistent controls and redundant cards, borders, or containers.
9. Define patterns for headers, labels, explanatory text, disabled states, errors, defaults, and advanced options.
10. Evaluate search within settings if the number and complexity of options justify it.
11. Define the behavior for applying, saving, resetting, migrating, and validating settings.
12. Investigate interactions between settings that affect the same feature.

For each existing setting, recommend one of the following: keep, move, merge, split, rename, replace the control, or remove as redundant. Justify every removal and any breaking migration.

### Before implementation, deliver

- A full inventory of the existing structure.
- The proposed settings information architecture.
- A mapping from old locations to new locations.
- A unified control and visual-pattern specification.
- Main user journeys and examples of finding common settings.
- A migration and compatibility plan.
- The affected files/components and dependencies.
- Risks, implementation stages, and acceptance criteria.

Wait for approval before beginning the major implementation. After approval, implement in small, reviewable slices and preserve existing functionality.

---

## 7. Lock-Screen Customization

### Initial change

Move LockScreen out of “Shell Apps” into a dedicated section of settings. First study the current navigation, configuration storage, runtime behavior, and rendering architecture. Do not create a duplicate implementation.

### Required customization

- Move supported elements using a grid-based layout.
- Show or hide individual elements.
- Configure blur.
- Choose wallpaper.
- Configure colors.
- Provide a shared “Follow theme” option for color settings where appropriate.

Define which elements can move, how the grid works, collision/overlap restrictions, and how default positions can be restored. Color inheritance should be explicit: follow the active theme or use a user-defined value where supported.

Research Noctalia Shell and relevant Windows, macOS, iOS, and Android patterns, while accounting for Linux-specific screen-locking constraints. Consider presets, reset, preview, display scaling, aspect ratios, and predictable application of changes.

Before implementing additions beyond the required scope, submit them as proposals for approval.

---

## 8. File Manager Improvements

### 8.1 Home page with storage overview

Add a file-manager home page inspired by the usability of Windows File Explorer. Show available disks/volumes/partitions and a visual representation of used and free space.

Research the relevant Linux APIs and clearly distinguish physical disks, partitions, filesystems, mount points, and network resources. Avoid duplicate or misleading representations.

Consider capacity, free space, mount state, unavailable devices, refresh behavior, permission errors, removable media, and network storage if supported by the current architecture.

### 8.2 Customizable sidebar

Allow users to customize the sidebar. Audit existing navigation items and propose a consistent mechanism for managing pinned locations and visible entries.

Support persistent ordering, adding/removing pins, sensible empty states, and restoring defaults, where appropriate.

### 8.3 Remove redundant borders

Remove extra frames around sections where they add no meaning. Do not delete borders mechanically; preserve visual hierarchy with spacing, grouping, typography, and the shared design system.

---

## 9. Bar, Island, Launcher, Keybinds, and Notch Mode

### 9.1 Open Launcher and Keybinds from the bar in Island mode

Add a way to open Launcher and Keybinds directly from the bar when it is in Island mode. The interaction should visually fit the existing module-opening behavior.

Audit the current Island, hub, module, Launcher, and Keybinds behavior. Propose entry points, expansion/collapse, repeat clicks, switching between modules, focus, keyboard interactions, outside clicks, and conflict handling with other open surfaces.

Do not put controls in arbitrary locations. Submit the interaction concept and affected components for approval before implementation.

### 9.2 New bar appearance: notch

Design a new bar mode inspired by the compact notch/Dynamic Island composition, adapted for a Linux desktop. Do not merely change the shape of the existing bar.

Audit:
- Bar architecture and modes.
- Hub and module integration.
- Expansion and collapse behavior.
- Window positioning and layer behavior.
- Animations and interactive regions.
- Focus and outside-click handling.
- Different resolutions and display configurations.
- Existing user settings and compatibility with the current Island mode.

Determine which changes can reuse existing components and which require architectural work. Define a separate configuration for the mode, predictable module expansion, state transitions, sizing/placement, and a way to return to an existing mode.

Submit research, a UX concept, architecture recommendations, file/component impact, migration plan, and acceptance criteria before implementation.

---

## 10. Music Subsystem and Yandex Music

### 10.1 Make Yandex Music integration optional in dotfiles installation

The dotfiles currently contain a Yandex Music integration script and module. Installation of both must be optional. A user must be able to install the Shell without the Yandex Music integration.

Review optionality across scripts, modules, dependencies, installation steps, services/autostart, update and removal flows, and error reporting. The absence of the integration must not break installation, startup, or unrelated features.

### 10.2 Create a provider-independent Music module

Rename the existing “Music” module and related code where necessary to prevent confusion with Yandex Music-specific functionality.

Create a generic player/status module that reflects music playback occurring in another application, wherever system metadata and controls are available. Investigate MPRIS and supported system interfaces.

Potential functionality:
- Track title and artist.
- Artwork where available.
- Playback state.
- Play/pause.
- Next/previous track.
- Additional actions exposed by the active player.

Do not bind the generic module to one provider or build a second audio engine unnecessarily. Reuse useful visual patterns from the current Yandex Music module while separating generic playback state from provider-specific logic.

Handle no active player, multiple players, unavailable metadata, and an application disappearing during playback.

### 10.3 Full Yandex Music application

Design a separate application with familiar music-player functionality, within the capabilities and constraints of the service and existing integration.

Audit the current Yandex Music module, scripts, API/library usage, settings, dependencies, and behavior. Document:
- Implemented features.
- Missing features.
- Duplicated functionality with the generic Music module.
- What belongs in the app versus the system module.
- Integration settings and new user journeys.
- Supported and unsupported service operations.

Research permissible and technically viable integration methods. Do not assume an official API exists for every required operation. Account for the limitations and maintenance risk of unofficial libraries or reverse-engineered interfaces.

Submit an architecture, UX, feature, dependency, and settings proposal for approval before implementing the full application.

---

## 11. Camera Application and Module Architecture

The current camera application/module setup requires review. The target experience should be clear and predictable, using Windows as one possible behavioral reference rather than a literal blueprint.

Audit the current structure, responsibilities, hardware access, entry points, dependencies, and interactions with other components.

Compare at least two approaches:

1. Keep the current app and module boundaries but correct responsibilities and behavior.
2. Split functionality into separate applications and separate modules where that provides a clear user and architectural benefit.

For each option, assess UX, complexity, reuse, system integration, regressions, maintenance, and fit with the project's architecture. You may propose a better alternative if supported by evidence.

Provide a current-architecture diagram, identified problems, a recommendation, a migration plan, and acceptance criteria. Do not treat “two apps and two modules” as mandatory until the audit substantiates it. Wait for approval before substantial restructuring.

---

## 12. Torrent Client

Create a torrent client that feels like a native part of the Shell, using the project's established UI/UX, component patterns, settings model, and coding conventions.

### 12.1 Research and design before coding

Audit existing applications, reusable components, design tokens, settings, background-task behavior, notifications, system-service integrations, and platform constraints.

Propose an architecture that separates the UI from the download engine. Evaluate a suitable existing engine rather than implementing the BitTorrent protocol from scratch by default.

Assess a sensible initial feature set, potentially including:
- Adding a torrent by magnet URI or `.torrent` file.
- Download queue and status.
- Progress and transfer rates.
- Pause/resume and removal.
- Seeding controls.
- File selection and destination directory.
- Speed and connection limits.
- Error handling and retry behavior.
- Storage settings and notifications.

Treat this as a candidate feature set to refine through research, not a requirement to implement everything in a first release.

Evaluate dependency health, licensing, platform compatibility, security implications, external component boundaries, and failure modes.

Deliver the UX flows, screens/states, component reuse plan, data/state model, engine interface, settings, dependency evaluation, testing strategy, and phased implementation plan. Wait for approval before implementation.

### 12.2 Subagent implementation

Once the design is approved, delegate bounded implementation tasks to a Haiku-level subagent if that model and delegation are available in the actual Claude Code environment.

Give each subagent explicit file boundaries, interfaces, constraints, requirements, and acceptance tests. The primary agent remains responsible for architecture, integration, consistency with the design system, code review, tests, and final acceptance.

Do not accept a result merely because it builds or renders a screen. Verify functional behavior and requirements.

---

## 13. Product-Wide UX and Customization Audit

Conduct a critical, user-centered assessment of the Shell as a product for people other than its author.

Evaluate:
- Installation and first-run experience.
- Discoverability and clarity of settings.
- Personalization breadth and consistency.
- Conflicting or interdependent settings.
- Different screen sizes, scaling, and multi-monitor configurations.
- Missing or unsupported hardware/services.
- Accessibility and keyboard navigation.
- Performance and resource usage.
- Recovery from errors and unavailable services.
- Settings migration and reset.
- Optional integrations and their removal.
- Documentation and extension points for new applications/modules.

Test meaningful combinations of settings, not only each option in isolation. Examples include multi-monitor wallpaper selection, theme-derived versus explicit colors, different bar modes with open modules, missing audio hardware, absent Yandex Music integration, runtime preference changes, and restoring defaults.

Create a ranked list of findings. For each finding, include evidence, user impact, severity, implementation complexity, risk, dependencies, and a recommendation.

Be candid. Do not label features successful merely because they exist. Submit proposed improvements for approval before expanding implementation scope.

---

## 14. Unified Project Documentation

Documentation must become a coordinated system rather than a collection of unrelated notes.

Inspect existing documents before creating new files. Reuse, merge, or update documents where appropriate; avoid competing sources of truth.

### 14.1 Required documentation set

Maintain the following documents, or clearly identify existing equivalents:

#### `SHELL_PROJECT_ROADMAP.md`

The single high-level view of all phases, priorities, dependencies, approval gates, current status, and next steps. Each major task should link to its separate instruction file.

#### `SHELL_ARCHITECTURE.md`

Describe the actual repository architecture, component responsibilities, boundaries, dependencies, event/state flows, system integrations, and approved architectural decisions. Update it when architecture changes.

#### `SHELL_DEVELOPMENT_GUIDELINES.md`

The binding project standard for UI/UX, architecture, naming, code style, settings, error handling, testing, refactoring, documentation, and review. It must be concrete enough to use as a pre-change and acceptance checklist.

#### `SHELL_DESIGN_SYSTEM.md`

Document design tokens, typography, spacing, dimensions, radii, borders, surfaces, colors, icons, controls, interaction states, transitions, overlays, and reuse rules. Derive specifics from the actual project rather than inventing tokens before inspecting it.

#### `SHELL_TESTING_AND_RELEASE.md`

Document verified validation commands, tests, build and packaging processes, manual regression scenarios, release checks, and known limitations. Never include commands as confirmed until they have been tested or verified against repository configuration.

#### `docs/decisions/README.md` and decision records

Record major architecture and design decisions, alternatives considered, rationale, trade-offs, date/status, and implications. Use one record per significant decision. Mark superseded decisions clearly.

#### `docs/implementation-plans/*.md`

Maintain a separate executable instruction for every phase. Each must include scope, context, investigation, constraints, dependencies, approval gates, implementation steps, acceptance criteria, testing, agent delegation, and reporting format.

### 14.2 Authoring standards

The development guidelines must distinguish:
- **MUST:** mandatory requirement.
- **SHOULD:** strong recommendation that may be departed from with documented justification.
- **MAY:** optional practice.

The documentation should not promise behavior the implementation does not provide. Mark proposals as proposals, approved decisions as approved, and completed features as implemented and verified only when evidence supports that status.

Avoid duplicating detailed rules in multiple documents. Each rule should have one authoritative location; other documents should link to it.

### 14.3 Update discipline

At the completion of each approved phase:

1. Update its implementation-plan status.
2. Update the roadmap.
3. Update architecture/design documentation if the change affects it.
4. Add or amend a decision record for material decisions.
5. Update testing/release guidance if validation procedures changed.
6. Record known issues and remaining work.

Do not rewrite the entire documentation set on every task. Update the smallest authoritative documents affected by the change.

---

## 15. Subagent Governance and Independent Review

Subagents are useful for parallel research, bounded implementation, and independent reviews, but they must not replace primary-agent responsibility.

Where available, use an independent Opus-level reviewer to review major audits and plans. The reviewer must receive the original requirements, audit evidence, proposed plan, and explicit evaluation criteria. It must challenge missing cases, unsupported assumptions, unnecessary complexity, accessibility issues, risks, and whether the proposal actually achieves the goal.

If the review confirms the proposal, record the reasoning; do not treat confirmation as an automatic approval from the project owner when owner approval is required. If it identifies issues, revise the plan and, where valuable, request a focused re-review.

After approval, delegate well-bounded implementation tasks to Haiku-level agents where available. The primary agent must:

- Define file boundaries and interfaces.
- Ensure tasks do not conflict or edit the same components concurrently.
- Provide the correct project guidelines and relevant task-specific instruction.
- Review every diff.
- Run or verify appropriate tests.
- Check visual and behavioral consistency.
- Resolve integration conflicts.
- Track each acceptance criterion.
- Give follow-up instructions for concrete failures.

Check which models, subagent features, and tool permissions actually exist. Do not pretend a requested model was used if it is unavailable. If unavailable, explain the limitation and perform the strongest feasible alternative, such as a separate review pass with the available model.

---

## 16. Testing, Acceptance, and Regression Control

Before defining validation commands, discover the actual tools in the project: tests, linters, formatters, type checks, build scripts, package managers, and packaging/install checks.

For every implementation phase:

- Review the complete diff.
- Verify only intended files changed.
- Run applicable automated tests and checks.
- Run a build or static analysis where supported.
- Test the important user scenarios.
- Check dependent components for regressions.
- Record what was not tested and why.

For settings, validate persistence, application without restart where intended, reopening the page, reset/default behavior, migration, and interactions with related settings.

For UI, inspect relevant states such as default, hover, focus, active, disabled, loading, error, empty, and unavailable where applicable.

For system integrations, consider missing hardware, missing services, inaccessible resources, changing device state, and malformed/unavailable responses where supported.

Never report manual verification that did not take place. If a test cannot run in the current environment, record the exact limitation and what remains to be validated.

---

## 17. Required Reporting Format

### For each implementation task

Report:

1. **Problem and root cause:** what was observed and what evidence supports the explanation.
2. **Changes:** files/components changed and a concise summary.
3. **Design/technical rationale:** why the selected approach was chosen over viable alternatives.
4. **Validation:** commands, tests, and manual scenarios actually run, with results.
5. **Regressions checked:** related functionality examined.
6. **Outstanding issues:** what remains uncertain, incomplete, or blocked.

### For research and planning tasks

Report:

1. Sources examined and why they were relevant.
2. Findings from the actual repository.
3. Methods and evaluation criteria used.
4. Alternatives considered.
5. Recommendations and rationale.
6. Dependencies, risks, estimates of relative effort if useful, and approval gates.
7. The exact next task instruction to execute.

### Final status categories

Every roadmap item must be assigned one of these states:

- **Implemented and verified.**
- **Implemented, partially verified.**
- **Researched/proposed; awaiting approval.**
- **Blocked, deferred, or not implemented.**

Explain why any item is blocked or deferred. State what improved for users and why, but do not claim success beyond the available evidence.

---

## 18. Initial Execution Instructions

For the first run, do only the following:

1. Inspect the repository structure and existing documentation.
2. Identify actual build, test, lint, format, and packaging mechanisms.
3. Map the key applications, modules, settings architecture, design system, installation flow, and system integrations.
4. Identify existing task/planning documents that can be reused.
5. Create or update `docs/SHELL_PROJECT_ROADMAP.md` and the repository audit instruction file.
6. Create a complete list of proposed phase-specific instruction files, with dependencies and approval gates.
7. Write the first actionable task instruction for the notification-system audit/fix, grounded in real file paths and existing conventions.
8. Report findings, unverified assumptions, risks, proposed phase order, and decisions requiring owner approval.

**Do not modify application code during this initial run. Do not begin large refactors, implement features, or launch implementation subagents yet.** Research/review agents may be used only if they are available and can work without modifying project code; describe the scope of their review.

The initial deliverable is a practical, repository-specific plan and a set of separate instructions that make the overall project manageable. After the owner reviews the plan, execute one approved phase at a time, updating the shared documentation as work progresses.

## 19. Definition of Overall Success

The project is successful when the Shell is more coherent and reliable, its settings and applications follow a consistent design language, important bugs are fixed at their root causes, optional integrations do not compromise installation, new applications fit the established architecture, and future development follows a documented and repeatable process.

A feature is not complete just because code was written. Completion requires meeting its acceptance criteria, checking regressions, reporting evidence, and updating the authoritative documentation.

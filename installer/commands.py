from installer.config import DOTFILES, HOME
from installer.ansi import C, ok, warn, fail, info, fix, header, divider
from installer.links import (
    Status,
    build_link_map,
    classify,
    is_same_link,
    resolve_conflict,
    create_symlink,
    cleanup_stale,
    stale_links,
    remove_empty_dirs,
)


def cmd_link(args):
    header("Linking dotfiles")

    stale_removed = cleanup_stale()
    if stale_removed:
        divider()

    links = build_link_map()
    created = skipped = 0

    for link in links:
        if not link.src.exists():
            warn(f"source missing, skipping: {link.src.relative_to(DOTFILES)}")
            if link.tgt.is_symlink():
                link.tgt.unlink()
                fix(f"removed broken symlink: {link.tgt.relative_to(HOME)}")
            continue

        if is_same_link(link.tgt, link.src):
            skipped += 1
            continue

        resolve_conflict(link.tgt)
        create_symlink(link.src, link.tgt)
        created += 1
        ok(f"{link.tgt.relative_to(HOME)}")

    divider()
    info(f"Created: {created} | Up to date: {skipped} | Stale removed: {stale_removed}")
    ok("Done")


def cmd_unlink(args):
    header("Removing managed symlinks")
    links = build_link_map()
    removed = 0

    for link in links:
        if link.tgt.is_symlink():
            link.tgt.unlink()
            removed += 1
            ok(f"removed: {link.tgt.relative_to(HOME)}")

    stale_removed = cleanup_stale()
    remove_empty_dirs()

    divider()
    info(f"Removed: {removed} | Stale removed: {stale_removed}")
    ok("Done")


def cmd_update(args):
    header("Updating \u2014 adding new files only")

    stale_removed = cleanup_stale()
    if stale_removed:
        divider()

    links = build_link_map()
    added = skipped = 0

    for link in links:
        if not link.src.exists():
            continue

        if is_same_link(link.tgt, link.src):
            skipped += 1
            continue

        if not resolve_conflict(link.tgt):
            warn(f"skipped (real dir): {link.tgt.relative_to(HOME)}")
            continue

        create_symlink(link.src, link.tgt)
        added += 1
        ok(f"+ {link.tgt.relative_to(HOME)}")

    divider()
    info(f"Added: {added} | Up to date: {skipped} | Stale removed: {stale_removed}")
    ok("Done")


def cmd_status(args):
    header("Package status")
    links = build_link_map()

    for link in links:
        link.status = classify(link)

    pkgs: dict[str, list] = {}
    for link in links:
        pkgs.setdefault(link.pkg, []).append(link)

    for pkg in sorted(pkgs):
        items = pkgs[pkg]
        n_linked = sum(1 for l in items if l.status == Status.LINKED)
        n_missing = sum(1 for l in items if l.status == Status.MISSING)
        n_problem = sum(
            1
            for l in items
            if l.status
            in (Status.CONFLICT, Status.WRONG, Status.BROKEN, Status.SOURCE_MISSING)
        )

        parts = []
        if n_linked:
            parts.append(f"{C.G}{n_linked} linked{C.X}")
        if n_missing:
            parts.append(f"{C.Y}{n_missing} missing{C.X}")
        if n_problem:
            parts.append(f"{C.R}{n_problem} problem{C.X}")
        status_str = " | ".join(parts) if parts else f"{C.D}no files{C.X}"

        print(f"    {pkg:20s} {status_str}")

    PROBLEM_MSGS = {
        Status.CONFLICT: (f"{C.R}\u2717{C.X}", "real file/dir"),
        Status.WRONG: (f"{C.R}\u2717{C.X}", "points elsewhere"),
        Status.BROKEN: (f"{C.R}\u2717{C.X}", "broken"),
        Status.SOURCE_MISSING: (f"{C.R}\u2717{C.X}", "source removed"),
    }

    problems = [l for l in links if l.status in PROBLEM_MSGS]
    if problems:
        print()
        info("Problems:")
        for l in problems:
            icon, msg = PROBLEM_MSGS[l.status]
            print(f"    {icon} {l.tgt.relative_to(HOME)} ({msg})")

    stale = stale_links()
    if stale:
        print()
        info(f"Stale symlinks ({len(stale)}):")
        for p in stale:
            print(f"    {C.R}\u2717{C.X} {p.relative_to(HOME)} (no longer managed)")
    print()


def cmd_verify(args):
    header("Checking symlinks")
    links = build_link_map()
    broken = 0

    for link in links:
        if link.tgt.is_symlink() and not link.tgt.exists():
            fail(f"BROKEN: {link.tgt.relative_to(HOME)}")
            broken += 1
        elif not link.src.exists():
            fail(
                f"SOURCE MISSING: {link.tgt.relative_to(HOME)} (source {link.src.relative_to(DOTFILES)} gone)"
            )
            broken += 1

    for p in stale_links():
        fail(f"STALE: {p.relative_to(HOME)}")
        broken += 1

    if broken == 0:
        ok("All symlinks OK")
    else:
        fail(f"{broken} broken symlink(s)")
        raise SystemExit(1)


def cmd_force(args):
    header("Force relinking")
    cmd_unlink(args)
    cmd_link(args)


def cmd_cleanup(args):
    header("Cleaning stale & broken symlinks")
    removed = cleanup_stale()
    divider()
    if removed:
        info(f"Removed: {removed}")
    else:
        ok("Nothing to clean")
    ok("Done")

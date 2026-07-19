import sys


class C:
    B  = "\033[1m"
    D  = "\033[2m"
    G  = "\033[32m"
    Y  = "\033[33m"
    R  = "\033[31m"
    CN = "\033[36m"
    M  = "\033[35m"
    BL = "\033[34m"
    X  = "\033[0m"
    CLR = "\033[2J\033[H"
    HID = "\033[?25l"
    SHW = "\033[?25h"


def ok(m):    print(f"  {C.G}\u2713{C.X} {m}")
def warn(m):  print(f"  {C.Y}!{C.X} {m}")
def fail(m):  print(f"  {C.R}\u2717{C.X} {m}")
def info(m):  print(f"  {C.CN}\u2192{C.X} {m}")
def skip(m):  print(f"  {C.D}\u2013 {C.X} {m}")
def fix(m):   print(f"  {C.M}\u26a1{C.X} {m}")


def header(m):
    print(f"\n  {C.B}{C.CN}{'\u2500' * 50}{C.X}")
    print(f"  {C.B}{m}{C.X}")
    print(f"  {C.B}{C.CN}{'\u2500' * 50}{C.X}\n")


def divider():
    print(f"  {C.D}{'\u2500' * 50}{C.X}")


def pause():
    print()
    input(f"  {C.D}Press Enter...{C.X}")

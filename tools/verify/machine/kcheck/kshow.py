#!/usr/bin/env python3
"""kshow: how a driver names things, and what it lets through to a reader's terminal.

b3(bytes): the BLAKE3 hash, all 64 digits. It is worked out by the specification of BLAKE3 in this folder
(blake3.spec, read by ode.py): there is no other code for the hash here, and `b3sum FILE` gives the same
digits. About 100 kB a second: enough for the texts and files a verification names.

Plain(stream): a stream that passes no control or formatting character but the end of a line. What a file
carries (a specification's comments, the names of its functions) is its maker's, and a terminal obeys such
characters: one can take back a line already written. Each is written out as \\xNN or \\uNNNN."""
import os, unicodedata
import ode

HERE = os.path.dirname(os.path.abspath(__file__))
_SPEC, _DONE = [], {}


def b3(data):
    data = bytes(data)
    if data not in _DONE:
        if not _SPEC:
            with open(os.path.join(HERE, "blake3.spec")) as f: _SPEC.append(ode.Spec(f.read()))
        if len(_DONE) > 64: _DONE.clear()
        _DONE[data] = bytes(_SPEC[0].call(ode.Numbers(), "blake3", list(data))).hex()
    return _DONE[data]


def plain(text):
    if text.isascii() and text.isprintable(): return text
    return "".join(c if c == "\n" or " " <= c <= "~" or (c > "\x7f" and unicodedata.category(c)[0] not in "CZ")
                   else (f"\\x{ord(c):02x}" if ord(c) < 256 else f"\\u{ord(c):04x}") for c in text)


class Plain:
    def __init__(self, stream): self.stream = stream
    def write(self, text): return self.stream.write(plain(text))
    def flush(self): self.stream.flush()
    def __getattr__(self, name): return getattr(self.stream, name)


def ends_said(line, maintain):
    """The line about the definitions' coming to an end, as a reader is told it. The definitions' names are
    their maker's: an auditor has no use for them here; a maintainer (--maintain) is given the line whole."""
    if maintain: return line
    if "NOT shown" in line: return "its definitions are NOT shown to come to an end on everything the contracts allow (a contract says nothing of an input on which a definition goes on for ever)"
    return "every definition its contracts use comes to an end on everything the contracts allow"

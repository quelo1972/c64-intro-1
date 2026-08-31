#!/usr/bin/env python3
"""Extract the C64 payload and player addresses from a PSID file."""

from __future__ import annotations

import hashlib
import json
import sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


def be16(data: bytes, offset: int) -> int:
    return int.from_bytes(data[offset : offset + 2], "big")


def write_if_changed(path: Path, contents: bytes) -> None:
    if path.exists() and path.read_bytes() == contents:
        return
    path.write_bytes(contents)


def fail(message: str) -> None:
    raise SystemExit(f"prepare_sid.py: {message}")


def references_address(payload: bytes, address: int) -> bool:
    """Return whether the SID payload contains an absolute reference to address."""
    return address.to_bytes(2, "little") in payload


PAL_FRAMES_PER_SECOND = Decimal("50")
RESTART_DELAY_SECONDS = Decimal("5")
# These tunes already restart their subtune internally. Reinitializing them
# from the intro a few seconds later causes an audible double restart.
SELF_LOOPING_SID_DIGESTS = {
    "7a4b88dcfbbf2f8a8944d555a541a58e",  # Warriors.sid
}


def load_duration_seconds(
    source: Path, digest: str, song_index: int, override: str
) -> Decimal:
    """Return the measured duration for the selected subtune."""
    if override:
        try:
            duration = Decimal(override)
        except Exception as error:
            fail(f"invalid SID_DURATION_SECONDS value {override!r}: {error}")
        if duration <= 0:
            fail("SID_DURATION_SECONDS must be greater than zero")
        return duration

    lengths_path = Path(__file__).with_name("sid_lengths.json")
    lengths = json.loads(lengths_path.read_text())
    durations = lengths.get(digest)
    if not durations or song_index >= len(durations):
        fail(
            f"{source} has no measured duration in {lengths_path.name}; "
            "rerun make with SID_DURATION_SECONDS=<seconds>"
        )
    return Decimal(str(durations[song_index]))


def main() -> None:
    if len(sys.argv) != 6:
        fail(
            "usage: prepare_sid.py INPUT.sid OUTPUT.asm OUTPUT.bin "
            "OUTPUT-vice-args SID_DURATION_SECONDS"
        )

    source, config_path, payload_path, vice_args_path = map(Path, sys.argv[1:5])
    duration_override = sys.argv[5]
    data = source.read_bytes()
    if len(data) < 0x76 or data[:4] not in (b"PSID", b"RSID"):
        fail(f"{source} is not a valid PSID/RSID file")

    data_offset = be16(data, 6)
    load = be16(data, 8)
    init = be16(data, 10)
    play = be16(data, 12)
    songs = be16(data, 14)
    default_song = be16(data, 16)
    if data_offset >= len(data):
        fail(f"{source} has no C64 payload")
    if not 1 <= default_song <= songs:
        fail(f"{source} has an invalid default song number")
    digest = hashlib.md5(data).hexdigest()
    duration_seconds = load_duration_seconds(
        source, digest, default_song - 1, duration_override
    )
    auto_restart = digest not in SELF_LOOPING_SID_DIGESTS
    restart_frames = (
        int(
            ((duration_seconds + RESTART_DELAY_SECONDS) * PAL_FRAMES_PER_SECOND)
            .to_integral_value(rounding=ROUND_HALF_UP)
        )
        if auto_restart
        else 0
    )
    if not 0 <= restart_frames <= 0xFFFF:
        fail(f"{source} restart time does not fit the C64 frame counter")

    payload = data[data_offset:]
    if load == 0:
        if len(payload) < 2:
            fail(f"{source} is missing the payload load address")
        load = int.from_bytes(payload[:2], "little")
        payload = payload[2:]
    if init == 0:
        init = load
    if play == 0:
        fail(f"{source} needs CIA-timer playback, which this 50 Hz player does not support")
    if load + len(payload) > 0x10000:
        fail(f"{source} payload exceeds C64 memory")
    payload_end = load + len(payload)
    fits_low_sid_area = 0x1000 <= load and payload_end <= 0x2800
    fits_basic_ram_area = 0xA000 <= load and payload_end <= 0xB200
    if not (fits_low_sid_area or fits_basic_ram_area):
        fail(
            f"{source} payload (${load:04x}-${payload_end - 1:04x}) does not fit "
            "a supported SID area ($1000-$27ff or $a000-$b1ff)"
        )
    sid_needs_basic_ram = int(load < 0xC000 and payload_end > 0xA000)

    # PSID v2NG stores extra SID addresses as $D000 + (header byte * $10).
    # A zero byte means that the corresponding chip is not used.
    sid2 = data[0x7A] if len(data) >= 0x7C else 0
    sid3 = data[0x7B] if len(data) >= 0x7C else 0
    if sid3 and not sid2:
        fail(f"{source} declares a third SID without a second SID")
    declared_extra_addresses = [0xD000 + value * 0x10 for value in (sid2, sid3) if value]
    # Some SID files retain multi-SID metadata although their player never
    # addresses the extra chips. Do not make VICE expose silent stereo channels
    # in that case: only enable chips referenced by the payload itself.
    extra_addresses = [
        address
        for address in declared_extra_addresses
        if references_address(payload, address)
    ]
    inactive_addresses = [
        address
        for address in declared_extra_addresses
        if address not in extra_addresses
    ]
    if inactive_addresses:
        ignored = ", ".join(f"${address:04x}" for address in inactive_addresses)
        print(f"prepare_sid.py: ignoring declared but unused extra SID address(es): {ignored}")
    vice_args = []
    if extra_addresses:
        vice_args.extend(("-sidextra", str(len(extra_addresses))))
        for index, address in enumerate(extra_addresses, start=2):
            vice_args.extend((f"-sid{index}address", f"0x{address:04x}"))

    config = (
        "; Generated by tools/prepare_sid.py; do not edit.\n"
        f"SID_LOAD = ${load:04x}\n"
        f"SID_INIT = ${init:04x}\n"
        f"SID_PLAY = ${play:04x}\n"
        f"SID_SONG = {default_song - 1}\n"
        f"SID_AUTO_RESTART = {int(auto_restart)}\n"
        f"SID_RESTART_FRAMES = {restart_frames}\n"
        f"SID_NEEDS_BASIC_RAM = {sid_needs_basic_ram}\n"
    ).encode()
    write_if_changed(config_path, config)
    write_if_changed(payload_path, payload)
    write_if_changed(vice_args_path, (" ".join(vice_args) + "\n").encode())


if __name__ == "__main__":
    main()

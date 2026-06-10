# Dell U4025QW BetterDisplay Profile

The EDID profile in `profiles/u4025qw-m1pro-100-110hz.edid.base64` is the
monitor-specific BetterDisplay override for this Dell U4025QW. It exposes
quality-preserving 100 Hz and 110 Hz modes for the Apple M1 Pro connection.

The profile is already applied in BetterDisplay with automatic reapplication
enabled. macOS Display Settings continues to expose the quality-preserving
3840x1620 HiDPI preset at 100 Hz, 60 Hz, and 30 Hz. BetterDisplay's refresh
rate menu exposes the separate 109.99 Hz option. Select it there or use the
helper script to switch to the same full-quality Dell connection mode:

```sh
./u4025qw-refresh.sh status
./u4025qw-refresh.sh 100
./u4025qw-refresh.sh 110
```

The helper refuses 120 Hz because this connection does not advertise a
quality-preserving 120 Hz mode. It also rejects any switch that drops the
3840x1620 HiDPI resolution or the 5120x2160 fixed 10-bit SDR RGB Full
connection quality. A native macOS Display Settings selector entry for 110 Hz
would require macOS to expose a 3840x1620 HiDPI 110 Hz mode, which this M1 Pro
connection does not currently advertise.

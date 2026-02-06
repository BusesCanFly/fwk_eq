# Framework Laptop 13 Speaker EQ (Linux)

Improve the internal speaker sound quality on the Framework Laptop 13 using [EasyEffects](https://github.com/wwmm/easyeffects) on PipeWire.

This uses [Kieran Levin's EQ profile](https://community.frame.work/t/speakers-sound-quality/1078?page=3), created by a Framework engineer who measured the actual frequency response of the FW13 speakers. The corrections target known hardware defects — not subjective preference:

| Band | Freq | Type | Gain | Why |
|------|------|------|------|-----|
| 0 | 80 Hz | Hi-pass | 0 dB | Roll off sub-bass the speakers can't reproduce |
| 1 | 600 Hz | Notch | -8 dB | Cut driver resonance (main source of muddiness) |
| 2 | 1,250 Hz | Bell | -3.49 dB | Reduce upper-mid harshness |
| 3 | 2,016 Hz | Bell | +4.85 dB | Boost vocal presence and clarity |
| 4 | 5,272 Hz | Notch | +3.83 dB | Compensate for front port structure dip |
| 5 | 6,000 Hz | Hi-shelf | +4.85 dB | Lift highs for air and detail |

The result is a flat, accurate response. It won't be super loud, but it will sound correct.

## Prerequisites

- Framework Laptop 13 (any generation)
- PipeWire (default on Pop!_OS, Fedora, Ubuntu 24.04+)
- Flatpak

## Setup

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
1. Install EasyEffects via Flatpak
2. Write the EQ preset
3. Configure auto-start on login
4. Launch EasyEffects and load the preset
5. Route audio through EasyEffects

## Verify

```bash
# The * should be on "Easy Effects Sink", not the hardware device
wpctl status | grep -A3 "Sinks:"

# Should show the equalizer in the processing chain
pw-cli ls Node 2>/dev/null | grep -A2 "ee_soe_equalizer"
```

Open the GUI to A/B test by toggling the equalizer on/off while playing audio:

```bash
flatpak run com.github.wwmm.easyeffects
```

## Optional: Hide the tray icon

Open EasyEffects > hamburger menu (top-right) > Preferences > disable the tray icon.

## Troubleshooting

**No audible difference when toggling EQ:**
Audio is bypassing EasyEffects. Check that `*` is on "Easy Effects Sink" in `wpctl status`. If not:

```bash
EE_SINK=$(pw-cli ls Node 2>/dev/null | grep -B2 'node.name = "easyeffects_sink"' | head -1 | awk '{print $2}' | tr -d ',')
wpctl set-default "$EE_SINK"
```

**"Preset not loaded correctly" error:**
The preset JSON requires bands nested under `"left"` and `"right"` objects. Bands placed directly under the equalizer object will fail on EasyEffects 8.x.

**EQ resets after reboot:**
Check that `~/.config/autostart/com.github.wwmm.easyeffects.desktop` exists and includes `-l Framework-13-Speakers`.

## Credits

- EQ profile by [Kieran Levin](https://community.frame.work/t/speakers-sound-quality/1078?page=3) (Framework engineer), based on measured speaker frequency response
- Additional community presets at [ceiphr/ee-framework-presets](https://github.com/ceiphr/ee-framework-presets)

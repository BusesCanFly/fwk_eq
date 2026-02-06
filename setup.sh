#!/usr/bin/env bash
set -euo pipefail

# Framework Laptop 13 Speaker EQ Setup
# Installs EasyEffects via Flatpak and applies Kieran Levin's measured EQ profile.
# Source: https://community.frame.work/t/speakers-sound-quality/1078?page=3

PRESET_NAME="Framework-13-Speakers"
PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/data/easyeffects/output"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "==> Installing EasyEffects via Flatpak..."
flatpak install -y flathub com.github.wwmm.easyeffects

echo "==> Launching EasyEffects to initialize config directories..."
timeout 5 flatpak run com.github.wwmm.easyeffects --gapplication-service || true
flatpak kill com.github.wwmm.easyeffects 2>/dev/null || true
sleep 1

echo "==> Writing EQ preset..."
# Kieran Levin's measured EQ profile (Framework engineer)
#
#   Band 0: 80 Hz hi-pass — roll off sub-bass the speakers can't reproduce
#   Band 1: 600 Hz notch -8 dB — cut driver resonance (main source of muddiness)
#   Band 2: 1250 Hz bell -3.49 dB — reduce upper-mid harshness
#   Band 3: 2016 Hz bell +4.85 dB — boost vocal presence/clarity
#   Band 4: 5272 Hz notch +3.83 dB — compensate for front port structure dip
#   Band 5: 6000 Hz hi-shelf +4.85 dB — lift highs for air and detail

mkdir -p "$PRESET_DIR"
cat > "$PRESET_DIR/$PRESET_NAME.json" << 'PRESET'
{
    "output": {
        "blocklist": [],
        "equalizer": {
            "input-gain": 0.0,
            "mode": "IIR",
            "num-bands": 6,
            "output-gain": 0.0,
            "split-channels": false,
            "left": {
                "band0": { "frequency": 80.0, "gain": 0.0, "mode": "RLC (BT)", "mute": false, "q": 4.36, "slope": "x1", "solo": false, "type": "Hi-pass" },
                "band1": { "frequency": 600.0, "gain": -8.0, "mode": "RLC (BT)", "mute": false, "q": 4.0, "slope": "x1", "solo": false, "type": "Notch" },
                "band2": { "frequency": 1250.0, "gain": -3.49, "mode": "RLC (BT)", "mute": false, "q": 4.17, "slope": "x1", "solo": false, "type": "Bell" },
                "band3": { "frequency": 2016.0, "gain": 4.85, "mode": "RLC (BT)", "mute": false, "q": 0.67, "slope": "x1", "solo": false, "type": "Bell" },
                "band4": { "frequency": 5272.0, "gain": 3.83, "mode": "RLC (BT)", "mute": false, "q": 2.64, "slope": "x1", "solo": false, "type": "Notch" },
                "band5": { "frequency": 6000.0, "gain": 4.85, "mode": "RLC (BT)", "mute": false, "q": 4.36, "slope": "x1", "solo": false, "type": "Hi-shelf" }
            },
            "right": {
                "band0": { "frequency": 80.0, "gain": 0.0, "mode": "RLC (BT)", "mute": false, "q": 4.36, "slope": "x1", "solo": false, "type": "Hi-pass" },
                "band1": { "frequency": 600.0, "gain": -8.0, "mode": "RLC (BT)", "mute": false, "q": 4.0, "slope": "x1", "solo": false, "type": "Notch" },
                "band2": { "frequency": 1250.0, "gain": -3.49, "mode": "RLC (BT)", "mute": false, "q": 4.17, "slope": "x1", "solo": false, "type": "Bell" },
                "band3": { "frequency": 2016.0, "gain": 4.85, "mode": "RLC (BT)", "mute": false, "q": 0.67, "slope": "x1", "solo": false, "type": "Bell" },
                "band4": { "frequency": 5272.0, "gain": 3.83, "mode": "RLC (BT)", "mute": false, "q": 2.64, "slope": "x1", "solo": false, "type": "Notch" },
                "band5": { "frequency": 6000.0, "gain": 4.85, "mode": "RLC (BT)", "mute": false, "q": 4.36, "slope": "x1", "solo": false, "type": "Hi-shelf" }
            }
        },
        "plugins_order": [
            "equalizer"
        ]
    }
}
PRESET

echo "==> Creating autostart entry..."
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/com.github.wwmm.easyeffects.desktop" << DESKTOP
[Desktop Entry]
Name=Easy Effects
Comment=Audio Effects for PipeWire Applications
Exec=flatpak run com.github.wwmm.easyeffects --gapplication-service -l $PRESET_NAME
Icon=com.github.wwmm.easyeffects
Type=Application
Categories=AudioVideo;Audio;
StartupNotify=false
X-GNOME-Autostart-enabled=true
DESKTOP

echo "==> Starting EasyEffects and loading preset..."
flatpak run com.github.wwmm.easyeffects --gapplication-service &
sleep 4
flatpak run com.github.wwmm.easyeffects -l "$PRESET_NAME"

echo "==> Routing audio through EasyEffects..."
EE_SINK=$(pw-cli ls Node 2>/dev/null | grep -B2 'node.name = "easyeffects_sink"' | head -1 | awk '{print $2}' | tr -d ',')
if [ -n "$EE_SINK" ]; then
    wpctl set-default "$EE_SINK"
    echo "    Default sink set to Easy Effects (node $EE_SINK)"
else
    echo "    WARNING: Could not find Easy Effects sink. Open EasyEffects and set it as default output manually."
fi

echo ""
echo "Done! To verify, run:"
echo "  wpctl status | grep -A3 'Sinks:'"
echo ""
echo "The * should be on 'Easy Effects Sink', not the hardware device."
echo "Open the GUI to A/B test: flatpak run com.github.wwmm.easyeffects"

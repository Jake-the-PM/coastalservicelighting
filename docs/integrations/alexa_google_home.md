# Coastal Lighting: Smart Home Integration Manual

This manual provides deep-tier technical instructions for integrating Coastal Lighting (WLED) systems with major voice assistants and smart home ecosystems.

## 🎙️ 1. Amazon Alexa Integration

Coastal Lighting supports Alexa through three primary paths, depending on the desired level of local vs. cloud control.

### Path A: Direct WLED Alexa Support (Zero-Lag Local)
WLED has native Alexa emulation. This is the fastest way to get basic control.
1.  **Hardware Config**: In the WLED web UI, go to `Config` -> `Sync Settings`.
2.  **Emulation**: Under `Alexa Amazon Echo`, check `Emulate Alexa device`.
3.  **Discovery**: Ask Alexa: *"Alexa, discover my devices."*
4.  **Usage**: Your zones will appear as "Light" devices.
    - *"Alexa, turn on Front Porch."*
    - *"Alexa, set Front Porch to 40%."*

### Path B: Homebridge coastal-relay (Advanced States)
For installers using the Coastal Relay Bridge:
1.  Install the `homebridge-wled` plugin on your gateway.
2.  Map each IP and MAC address captured by the Coastal Lighting app into the Homebridge config.
3.  Enable the "Alexa" skill within Homebridge.

---

## 🏗️ 2. Apple HomeKit (Siri)

Coastal Lighting is optimized for HomeKit via the **Homebridge Coastal Gateway**.

### Setup Steps:
1.  **Gateway Pairing**: Open the Apple Home app.
2.  **Add Accessory**: Scan the QR code provided on your Coastal Bridge setup screen.
3.  **Zone Mapping**: The Coastal app automatically exports your zones as HomeKit `Lightbulb` services.

---

## 🌐 3. Google Home (Assistant)

Google Home integration requires the **Coastal Cloud Relay** (Supabase Bridge).

### Steps:
1.  **Account Link**: In the Google Home app, tap `+` -> `Set up device` -> `Works with Google`.
2.  **Search**: Search for "WLED" or use the custom "Coastal Lighting" action.
3.  **Login**: Authenticate with your Coastal Services account.

---

## 🛠️ 4. Troubleshooting & Deep Triage

| Issue | Potential Cause | Correction |
|-------|----------------|------------|
| "Device Unresponsive" | IP Shift | The Coastal app handles mDNS self-healing, but Alexa requires a rediscovery. Ask: *"Alexa, discover devices."* |
| Color mismatch | RGB Order | WLED RGB order must be set in the hardware config. |
| Sync Lag | API Latency | Say: *"Hey Google, sync my devices."* |

---

> [!IMPORTANT]
> **A Note on Privacy**: All voice commands are processed locally when using Path A. For remote access, the **Coastal Bridge** must be online.

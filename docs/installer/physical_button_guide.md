# Coastal Services Lighting - Hardware Guide

## Physical Button Integration
To achieve the "Wife Approval Factor" (WAF), every controller must have a physical wall switch. We use a **Momentary Push Button** wired to the controller.

### 1. Wiring Diagram
*   **Controller:** ESP8266 / ESP32 (WLED)
*   **Switch Type:** Momentary (Normally Open)
*   **Connections:**
    *   **Side A:** `GPIO 0` (Labelled **D3** on D1 Mini)
    *   **Side B:** `GND` (Ground)

```ascii
[ WLED Controller ]
|                 |
|      D3 (GPIO0) o--------[ \ ]--------o GND
|                 |       Switch
|_________________|
```

### 2. WLED Configuration
The software must be configured to interpret the button press as a "Toggle" command.

#### Method A: Via WLED Web UI
1.  Go to **Config > Time & Macros**.
2.  Under **Buttons**, ensure `Button 0` is set to:
    *   **Pin:** 0
    *   **Type:** Pushbutton
3.  Under **Button Actions**:
    *   **Short Press:** `1` (This refers to Preset 1)
4.  Go to **Presets**.
5.  Create **Preset 1**:
    *   **Name:** "Toggle Power"
    *   **API Command:** `T=2` (or JSON `{"on":"t"}`)
    *   **Save**.

#### Method B: Via wled_provision.json (Coastal App)
1.  Load the `wled_provision.json` file into the Coastal App (Future Feature).
2.  This will automatically create a "Toggle" preset (ID: 1) and map Button 0 to it.

## Troubleshooting
*   **Lights Flash on Boot:** GPIO 0 determines boot mode. If held down during power-up, the chip enters flash mode. **Ensure the button is NOT pressed when powering on the breaker.**
*   **No Response:** Check solder joints on GND. Verify "Button 0" is not disabled in Config.

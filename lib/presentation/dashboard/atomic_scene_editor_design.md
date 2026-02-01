# Atomic Scene Editor Design (Phase 2)

**Objective:** Shatter the "Gear Fiasco". Unify Visuals and Logic into a single, immersive editor.

## Layout Structure (Vertical Scroll)

1.  **Header (Pinned/Floating)**
    *   Icon + Title ("Welcome").
    *   Close Button.
    *   **NO GEAR ICON.**

2.  **Section 1: The Stage (Visual Preview)**
    *   A dynamic representation of the LED strip.
    *   Visualizes the `Start`, `Count`, and `Color` in real-time.
    *   *Implementation:* Reuse `SpectrumPicker` but maybe add a linear "Strip Preview" widget later. For now, Spectrum Picker is the hero.

3.  **Section 2: Design (Look & Feel)**
    *   **Color Wheel**: Centered.
    *   **Effect Selector**: Horizontal scrolling list or Wrap (Chips).

4.  **Section 3: Logic (Behavior)** (Formerly Hidden in Gear)
    *   **"Zone Boundaries"**:
        *   Start LED Slider.
        *   Length (Count) Slider.
        *   *Visual:* Render as a linear bar showing the active segment relative to 150 LEDs.
    *   **Timing**:
        *   Duration Slider (Seconds).

5.  **Section 4: Integration (The Vault)**
    *   **Webhook URL**:
        *   Masked by default (`https://.../hook/••••`).
        *   "Copy" button.
        *   "Regenerate" button (Mocked for now).

6.  **Footer (Floating)**
    *   Row: [Test Trigger] [Save & Close].

## Trace Matrix (Verification)

*   **Trace 1 (Connect):** Sliders must update the "Stage" preview immediately.
*   **Trace 2 (Resilience):** Dragging sliders fast must not choke the Driver (throttle calls?).
*   **Trace 3 (Integration):** "Save" must persist to `LightingRepository`.

## Gate 1 Logic Check
*   Does this expose all settings? **Yes.**
*   Is it accessible? **Yes**, single scroll view is better than hidden tabs.
*   Is it secure? **Yes**, masking webhook.

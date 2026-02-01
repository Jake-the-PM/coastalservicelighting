# Coastal Lighting: Hardware Masterclass & Field Engineering

This guide is designed for professional installers to ensure long-term stability and performance in Coastal environments.

## 🔋 1. Power Distribution & Voltage Drop

Voltage drop is the #1 cause of "flickering" or "yellowing" in long runs.

### Voltage Drop Tables (30m Run / 100W Load)
| Wire Gauge (AWG) | 5V Run (Drop) | 12V Run (Drop) | 24V Run (Drop) | Recommendation |
|------------------|---------------|----------------|----------------|----------------|
| 18 AWG | 1.8V (36%) | 1.8V (15%) | 1.8V (7%) | ⚠️ High Risk |
| 16 AWG | 1.2V (24%) | 1.2V (10%) | 1.2V (5%) | ✅ Good for 12V |
| 14 AWG | 0.8V (16%) | 0.8V (6%) | 0.8V (3%) | 💎 Elite for 24V |

### Power Injection Strategy
- **Rule of Thumb**: Inject power every 15m (50ft) for 12V systems, or every 5m (16ft) for 5V systems.
- **Topography**: Use a "Parallel Bush" topology where power leads are run in parallel to the main data line.

---

## 🌩️ 2. Environmental Hardening (Coastal Specs)

Coastal environments present unique challenges (salt spray, humidity, heat).

### Enclosure Design
1.  **Ventilation**: Use IP66-rated enclosures with Gore-Tex vents to allow pressure equalization without letting in moisture.
2.  **Heat Dissipation**: ESP32 controllers and power supplies generate significant heat. Always use a metal mounting plate to act as a heat sink.
3.  **Corrosion Control**: Use dielectric grease on all internal screw terminals and connector pins.

---

## 📡 3. Antenna & Signal Optimization

Steel roofs and stucco walls are Wi-Fi killers.

1.  **Antenna Offset**: If the enclosure is metal, you **must** use an external SMA antenna.
2.  **RSSI Targets**: Aim for a minimum RSSI of **-65 dBm**. Use the Coastal Diagnostic Tool to verify signal strength at the installation point.
3.  **WAP Placement**: Recommend dedicated 2.4GHz outdoor access points for large estate installations.

---

## 🏗️ 4. Controller Pinouts & Button Wiring

Coastal Lighting supports physical override buttons.

- **Button Pin (GPIO 0 / D3)**: Wire a momentary tactile switch between GPIO 0 and Ground. 
- **Action**: 
    - Short Press: Toggle Power.
    - Double Press: Cycle Scenes.
    - Long Press (5s): Reset WiFi.

---

> [!CAUTION]
> **Safety First**: Always use UL-listed Class 2 power supplies. Ensure all high-voltage connections (110V/220V) are handled by a licensed electrician.

---
description: How to launch the DareDay app on a physical phone
---

### Prerequisites
1.  **Enable Developer Options**: Go to Settings > About Phone > Tap 'Build Number' 7 times.
2.  **Enable USB Debugging**: Go to Settings > Developer Options > Enable 'USB Debugging'.
3.  **Connect Device**: Plug your phone into your PC via USB cable. If prompted on the phone, 'Allow USB Debugging'.

### Launch Steps
1.  Open your terminal/command prompt.
2.  Navigate to the project directory: `c:\Users\safar\Desktop\Dare_Day\dare_day`
3.  Check if your device is connected:
    ```bash
    flutter devices
    ```
4.  Launch the app:
    ```bash
    flutter run
    ```
    *If you have multiple devices connected, specify yours:*
    ```bash
    flutter run -d R8JN7PDYQ88LTO9H
    ```

### Troubleshooting
- If the phone isn't detected, try a different USB cable or port.
- Ensure the connection mode is set to "File Transfer" or "MTP" on the phone.
- Run `flutter doctor` to check for any environment issues.

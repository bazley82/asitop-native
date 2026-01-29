# ASITOP Native

A native macOS Menu Bar application implementation of the popular [asitop](https://github.com/tlkh/asitop) performance monitor.

![ASITOP Native](https://socialify.git.ci/barriesanders/asitop-native/image?description=1&font=Inter&language=1&name=1&owner=1&pattern=Circuit%20Board&theme=Dark)

## Credits
This project is a native implementation inspired by the original [asitop](https://github.com/tlkh/asitop) created by **[tlkh](https://github.com/tlkh)**.

## Features
- **Real-time Metrics**: CPU, GPU, ANE (Neural Engine), and RAM usage.
- **Modern UI**: Built with SwiftUI for a premium macOS look and feel.
- **Menu Bar Integration**: Quick access to your system performance.
- **Zero Configuration**: Automatic permission handling for `powermetrics`.

## Installation
1. Download the latest `ASITOP.zip` from the [Releases](https://github.com/barriesanders/asitop-native/releases) page.
2. Extract the zip file.
3. Move `ASITOP.app` to your `/Applications` folder.
4. Launch the app and click **Unlock Metrics** to authorize `powermetrics` access.

## Build from Source
If you wish to build it yourself:
```bash
./build_app.sh
```

## License
MIT

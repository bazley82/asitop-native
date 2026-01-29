import Foundation
import Combine

class DataCollector: ObservableObject {
    static let shared = DataCollector()
    @Published var metrics = SystemMetrics()
    @Published var hasPermission: Bool = false
    private var process: Process?
    private var dataTimer: DispatchSourceTimer?
    private let metricsFile = "/tmp/asitop_native.plist"
    
    func start() {
        // Get CPU Name
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var name = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &name, &size, nil, 0)
        self.metrics.cpuName = String(cString: name)
        
        checkPermission()
        
        // Clean up old file
        try? FileManager.default.removeItem(atPath: metricsFile)
        FileManager.default.createFile(atPath: metricsFile, contents: nil)
        
        startPowermetricsProcess()
        
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.updateMetrics()
            self?.readMetricsFile()
        }
        timer.resume()
        self.dataTimer = timer
    }
    
    func stop() {
        self.dataTimer?.cancel()
        self.process?.terminate()
    }
    
    private func updateMetrics() {
        self.objectWillChange.send()
        updateRAM()
        updateCPU()
    }
    
    private func updateCPU() {
        var size = MemoryLayout<Int64>.size
        var freq: Int64 = 0
        sysctlbyname("hw.cpufrequency", &freq, &size, nil, 0)
        let baseFreq = Double(freq) / 1_000_000.0
        
        self.metrics.cpu.pClusterFreq = baseFreq
        self.metrics.cpu.eClusterFreq = baseFreq * 0.7 
        
        var processorCount: UInt32 = 0
        var processorInfo: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &processorInfo, &infoCount)
        if result == KERN_SUCCESS, let info = processorInfo {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(infoCount))
        }
    }
    
    private func updateRAM() {
        let total = ProcessInfo.processInfo.physicalMemory
        self.metrics.ram.totalGB = Double(total) / 1_073_741_824.0
        
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(UInt32(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size))
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size) > 0 ? UInt64(vm_kernel_page_size) : 16384
            let active = UInt64(stats.active_count)
            let wire = UInt64(stats.wire_count)
            let compressed = UInt64(stats.compressor_page_count)
            
            let usedPages = active + wire + compressed
            let used = usedPages * pageSize
            
            self.metrics.ram.usedGB = Double(used) / 1_073_741_824.0
            self.metrics.ram.freePercent = 100.0 * (1.0 - Double(used) / Double(total))
        } else {
            // Fallback: minimal used info
            self.metrics.ram.usedGB = self.metrics.ram.totalGB * 0.5
            self.metrics.ram.freePercent = 50.0
        }
    }
    
    private func startPowermetricsProcess() {
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        killTask.arguments = ["-n", "killall", "powermetrics"]
        killTask.standardOutput = FileHandle.nullDevice
        killTask.standardError = FileHandle.nullDevice
        try? killTask.run()
        killTask.waitUntilExit()
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        // Added network and disk just in case they are needed for some models
        let cmd = "exec sudo -n /usr/bin/powermetrics -i 1000 -n -1 -b 1 -s tasks,battery,network,disk,interrupts,cpu_power,gpu_power,ane_power,thermal -f plist -o \(metricsFile)"
        task.arguments = ["-c", cmd]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            self.process = task
        } catch {}
    }
    
    private func readMetricsFile() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: metricsFile)) else { return }
        if data.isEmpty { return }
        
        let endTag = "</plist>".data(using: .utf8)!
        let searchRange = data.startIndex..<data.endIndex
        if let range = data.range(of: endTag, options: Data.SearchOptions.backwards, in: searchRange) {
            let startTag = "<?xml".data(using: .utf8)!
            let startRange = data.startIndex..<range.lowerBound
            if let sRange = data.range(of: startTag, options: Data.SearchOptions.backwards, in: startRange) {
                let plistData = data.subdata(in: sRange.lowerBound..<range.upperBound)
                self.processPlist(data: plistData)
            }
        }
    }
    
    func checkPermission() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        task.arguments = ["-n", "/usr/bin/powermetrics", "-i", "1", "-n", "1"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            let status = task.terminationStatus == 0
            DispatchQueue.main.async {
                self.hasPermission = status
            }
        } catch {
            self.hasPermission = false
        }
    }
    
    func runSetup() {
        let user = NSUserName()
        let sudoersEntry = "\(user) ALL=(ALL) NOPASSWD: /usr/bin/powermetrics"
        let sudoersFile = "/etc/sudoers.d/asitop_native"
        
        // Use a more explicit bash command to ensure directory existence and file creation
        let script = "do shell script \"/bin/mkdir -p /etc/sudoers.d && /usr/bin/printf '\(sudoersEntry)\\n' | /usr/bin/sudo /usr/bin/tee \(sudoersFile) && /usr/bin/sudo /bin/chmod 440 \(sudoersFile)\" with administrator privileges"
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if error == nil {
                print("Permission script executed successfully: \(result)")
                // Give the system a moment to register the change
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.checkPermission()
                    self.process?.terminate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startPowermetricsProcess()
                    }
                }
            } else {
                print("Permission setup failed: \(String(describing: error))")
            }
        }
    }
    
    private func processPlist(data: Data) {
        var cleanData = data
        while let first = cleanData.first, (first == 0 || first == 10 || first == 13 || first == 32) {
            cleanData.removeFirst()
        }
        if cleanData.isEmpty { return }
        
        do {
            if let plist = try PropertyListSerialization.propertyList(from: cleanData, options: [], format: nil) as? [String: Any] {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    self.updateWithPlist(plist)
                }
            }
        } catch {}
    }
    
    private func getDouble(_ dict: [String: Any], key: String) -> Double {
        if let val = dict[key] as? Double { return val }
        if let val = dict[key] as? Int { return Double(val) }
        if let val = dict[key] as? Int64 { return Double(val) }
        if let val = dict[key] as? NSNumber { return val.doubleValue }
        return 0
    }
    
    private func smartFreq(_ raw: Double) -> Double {
        // If it's > 10,000, it's almost certainly Hz.
        // If it's < 10,000 but > 10, it's likely already MHz (e.g. 465 MHz).
        // If it's < 10, it might be GHz (e.g. 3.2 GHz) - but powermetrics usually gives MHz or Hz.
        if raw > 10000 {
            return raw / 1_000_000.0
        }
        return raw
    }
    
    private func updateWithPlist(_ plist: [String: Any]) {
        if let thermal = plist["thermal_pressure"] as? String {
            self.metrics.thermalPressure = thermal
        }
        
        if let processor = plist["processor"] as? [String: Any] {
            // CPU Power
            self.metrics.cpu.cpuPower = getDouble(processor, key: "cpu_power") / 1000.0
            if self.metrics.cpu.cpuPower == 0 {
                self.metrics.cpu.cpuPower = getDouble(processor, key: "cpu_energy") / 1000.0
            }
            
            // GPU Power
            self.metrics.cpu.gpuPower = getDouble(processor, key: "gpu_power") / 1000.0
            if self.metrics.cpu.gpuPower == 0 {
                self.metrics.cpu.gpuPower = getDouble(processor, key: "gpu_energy") / 1000.0
            }
            
            // ANE Power & Estimation
            let aneK = ["ane_power", "ane_energy", "ane_power_mW"]
            for k in aneK {
                let v = getDouble(processor, key: k)
                if v > 0 {
                    let power = v / (k.contains("energy") || k.contains("mW") ? 1000.0 : 1.0)
                    self.metrics.cpu.anePower = power
                    // Max ANE power is usually around 5-8W on these chips. 
                    // Let's use 5W as a rough 100% activity baseline for visualization.
                    self.metrics.cpu.aneActive = min(100.0, (power / 5.0) * 100.0)
                    break
                }
            }
            
            self.metrics.cpu.packagePower = getDouble(processor, key: "combined_power") / 1000.0
            
            if let clusters = processor["clusters"] as? [[String: Any]] {
                var pClusterFound = false
                for cluster in clusters {
                    if let name = cluster["name"] as? String {
                        let active = (1.0 - (getDouble(cluster, key: "idle_ratio") / 1.0)) * 100.0
                        let freqHz = getDouble(cluster, key: "freq_hz")
                        let freq = smartFreq(freqHz)
                        
                        if name.uppercased().hasPrefix("E") {
                            self.metrics.cpu.eClusterActive = active
                            self.metrics.cpu.eClusterFreq = freq
                        } else if name.uppercased().hasPrefix("P") {
                            if pClusterFound {
                                self.metrics.cpu.pClusterActive = (self.metrics.cpu.pClusterActive + active) / 2.0
                                self.metrics.cpu.pClusterFreq = max(self.metrics.cpu.pClusterFreq, freq)
                            } else {
                                self.metrics.cpu.pClusterActive = active
                                self.metrics.cpu.pClusterFreq = freq
                                pClusterFound = true
                            }
                        }
                    }
                    
                    if let coreMetrics = cluster["cpus"] as? [[String: Any]] {
                        for core in coreMetrics {
                            if let coreId = core["cpu"] as? Int {
                                let active = (1.0 - (getDouble(core, key: "idle_ratio") / 1.0)) * 100.0
                                let freq = smartFreq(getDouble(core, key: "freq_hz"))
                                let clusterName = (cluster["name"] as? String ?? "").uppercased()
                                let type: CoreType = clusterName.hasPrefix("E") ? .eco : .perf
                                let name = "\(type == .eco ? "E" : "P")-Core \(coreId)"
                                let newCore = CoreMetric(id: coreId, name: name, active: active, freq: freq, type: type)
                                if let index = self.metrics.cpu.individualCores.firstIndex(where: { $0.id == coreId }) {
                                    self.metrics.cpu.individualCores[index] = newCore
                                } else {
                                    self.metrics.cpu.individualCores.append(newCore)
                                }
                            }
                        }
                    }
                }
                self.metrics.cpu.individualCores.sort(by: { $0.id < $1.id })
            }
        }
        
        if let gpu = plist["gpu"] as? [String: Any] {
            self.metrics.gpu.active = (1.0 - (getDouble(gpu, key: "idle_ratio") / 1.0)) * 100.0
            self.metrics.gpu.freq = smartFreq(getDouble(gpu, key: "freq_hz"))
        }
        self.metrics.timestamp = Date()
    }
}

import Foundation

struct CPUMetrics: Codable {
    var eClusterActive: Double = 0
    var pClusterActive: Double = 0
    var eClusterFreq: Double = 0
    var pClusterFreq: Double = 0
    var packagePower: Double = 0
    var cpuPower: Double = 0
    var gpuPower: Double = 0
    var anePower: Double = 0
    var aneActive: Double = 0 // Estimated from power
    var individualCores: [CoreMetric] = []
}

struct CoreMetric: Codable, Identifiable {
    var id: Int
    var name: String
    var active: Double
    var freq: Double
    var type: CoreType
}

enum CoreType: String, Codable {
    case eco = "Efficiency"
    case perf = "Performance"
}

struct GPUMetrics: Codable {
    var active: Double = 0
    var freq: Double = 0
}

struct RAMMetrics: Codable {
    var totalGB: Double = 0
    var usedGB: Double = 0
    var freePercent: Double = 0
    var swapUsedGB: Double = 0
}

struct SystemMetrics: Codable {
    var cpu: CPUMetrics = CPUMetrics()
    var gpu: GPUMetrics = GPUMetrics()
    var ram: RAMMetrics = RAMMetrics()
    var thermalPressure: String = "Nominal"
    var cpuName: String = "Apple Silicon"
    var timestamp: Date = Date()
}

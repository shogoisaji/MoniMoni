import Foundation
import IOKit

/// Apple SMC からセンサー値を読む（温度など）
/// サンドボックス外でのみ安定して動作します。
final class SMCReader {
    private var connection: io_connect_t = 0

    // Apple Silicon / Intel でよく使われる CPU 関連温度キー
    private static let cpuTemperatureKeys: [String] = [
        // Apple Silicon ダイ / クラスタ
        "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0T", "Tp0X",
        "Tp0b", "Tp0f", "Tp0j",
        // Intel 系
        "TC0P", "TC0E", "TC0F", "TC0H", "TC0D", "TC0C",
        "TC1C", "TC2C", "TC3C", "TC4C",
        // 汎用
        "Th0H", "Th1H", "Ts0S", "Ts0P"
    ]

    deinit {
        close()
    }

    @discardableResult
    func open() -> Bool {
        if connection != 0 { return true }

        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        let kr = IOServiceOpen(service, mach_task_self_, 0, &connection)
        return kr == KERN_SUCCESS
    }

    func close() {
        if connection != 0 {
            IOServiceClose(connection)
            connection = 0
        }
    }

    /// 利用可能な CPU 温度センサーの中央値（℃）
    func readCPUTemperature() -> Double? {
        guard open() else { return nil }

        var values: [Double] = []
        for key in Self.cpuTemperatureKeys {
            if let value = readTemperature(key: key), value > 0, value < 150 {
                values.append(value)
            }
        }

        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    private func readTemperature(key: String) -> Double? {
        guard let info = keyInfo(for: key) else { return nil }
        guard let bytes = readBytes(key: key, size: info.dataSize) else { return nil }

        let type = fourCharCodeToString(info.dataType)
        return Self.decodeTemperature(dataType: type, bytes: bytes)
    }

    /// SMCのデータ型を温度へ変換する。未文書化APIの不正なサイズは安全に無視する。
    static func decodeTemperature(dataType: String, bytes: [UInt8]) -> Double? {
        switch dataType {
        case "sp78":
            guard bytes.count >= 2 else { return nil }
            let integer = Int8(bitPattern: bytes[0])
            let fraction = Double(bytes[1]) / 256.0
            return Double(integer) + fraction
        case "flt ":
            guard bytes.count >= 4 else { return nil }
            var floatBits: UInt32 = 0
            floatBits |= UInt32(bytes[0])
            floatBits |= UInt32(bytes[1]) << 8
            floatBits |= UInt32(bytes[2]) << 16
            floatBits |= UInt32(bytes[3]) << 24
            return Double(Float(bitPattern: floatBits))
        case "ui16":
            guard bytes.count >= 2 else { return nil }
            let value = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(value)
        case "ui8 ":
            guard !bytes.isEmpty else { return nil }
            return Double(bytes[0])
        default:
            // 多くの温度センサーは sp78 相当の2バイト
            if bytes.count >= 2 {
                let integer = Int8(bitPattern: bytes[0])
                let fraction = Double(bytes[1]) / 256.0
                let candidate = Double(integer) + fraction
                if candidate > 0 && candidate < 150 {
                    return candidate
                }
            }
            return nil
        }
    }

    private func keyInfo(for key: String) -> SMCKeyInfoData? {
        var input = SMCKeyData()
        input.key = stringToFourCharCode(key)
        input.data8 = UInt8(kSMCGetKeyInfo)

        var output = SMCKeyData()
        let kr = call(input: &input, output: &output)
        guard kr == kIOReturnSuccess else { return nil }
        return output.keyInfo
    }

    private func readBytes(key: String, size: UInt32) -> [UInt8]? {
        var input = SMCKeyData()
        input.key = stringToFourCharCode(key)
        input.keyInfo.dataSize = size
        input.data8 = UInt8(kSMCReadKey)

        var output = SMCKeyData()
        let kr = call(input: &input, output: &output)
        guard kr == kIOReturnSuccess else { return nil }

        let count = Int(size)
        guard count > 0, count <= 32 else { return nil }

        return withUnsafeBytes(of: output.bytes) { rawBuffer in
            Array(rawBuffer.prefix(count))
        }
    }

    private func call(input: inout SMCKeyData, output: inout SMCKeyData) -> kern_return_t {
        let inputSize = MemoryLayout<SMCKeyData>.stride
        var outputSize = MemoryLayout<SMCKeyData>.stride

        return IOConnectCallStructMethod(
            connection,
            UInt32(kSMCHandleYPCEvent),
            &input,
            inputSize,
            &output,
            &outputSize
        )
    }

    private func stringToFourCharCode(_ string: String) -> UInt32 {
        let chars = Array(string.utf8)
        var result: UInt32 = 0
        for i in 0..<4 {
            let byte: UInt8 = i < chars.count ? chars[i] : 32
            result = (result << 8) | UInt32(byte)
        }
        return result
    }

    private func fourCharCodeToString(_ code: UInt32) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? ""
    }
}

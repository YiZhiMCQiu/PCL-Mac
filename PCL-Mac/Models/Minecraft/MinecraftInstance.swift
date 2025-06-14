//
//  MinecraftVersion.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation

public class MinecraftInstance: Identifiable {
    private static let RequiredJava16: any MinecraftVersion = SnapshotMinecraftVersion.fromString("21w19a")!
    private static let RequiredJava17: any MinecraftVersion = ReleaseMinecraftVersion.fromString("1.18")!
    private static let RequiredJava21: any MinecraftVersion = SnapshotMinecraftVersion.fromString("24w14a")!
    
    public let runningDirectory: URL
    public let version: any MinecraftVersion
    public var process: Process?
    public let manifest: ClientManifest!
    public var config: MinecraftConfig
    
    public let id: UUID = UUID()
    
    public init?(runningDirectory: URL, config: MinecraftConfig? = nil) {
        self.runningDirectory = runningDirectory
        
        do {
            let handle = try FileHandle(forReadingFrom: runningDirectory.appending(path: runningDirectory.lastPathComponent + ".json"))
            manifest = .decode(try handle.readToEnd()!)
            version = fromVersionString(manifest.id)!
        } catch {
            err("无法加载客户端 JSON: \(error)")
            return nil
        }
        
        let configPath = runningDirectory.appending(path: ".PCL_Mac.json")
        
        if FileManager.default.fileExists(atPath: configPath.path) {
            do {
                let handle = try FileHandle(forReadingFrom: configPath)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                self.config = try decoder.decode(MinecraftConfig.self, from: handle.readToEnd()!)
            } catch {
                err("无法加载配置: \(error.localizedDescription)")
                debug(configPath.path)
                return nil
            }
        } else {
            self.config = config ?? MinecraftConfig(name: runningDirectory.lastPathComponent)
            // 保存配置
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            do {
                try FileManager.default.createDirectory(
                    at: runningDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                try encoder.encode(config).write(to: configPath, options: .atomic)
            } catch {
                err("无法保存配置: \(error.localizedDescription)")
            }
        }
        
        // 检查 Java 路径是否存在
        if self.config.javaPath == nil {
            self.config.javaPath = MinecraftInstance.findSuitableJava(version)?.executableUrl.path
        }
    }
    
    public static func findSuitableJava(_ version: any MinecraftVersion) -> JavaVirtualMachine? {
        let needsJava16: Bool = version >= RequiredJava16
        let needsJava17: Bool = version >= RequiredJava17
        let needsJava21: Bool = version >= RequiredJava21
        
        var suitableJava: JavaVirtualMachine?
        for jvm in DataManager.shared.javaVirtualMachines.sorted(by: { $0.version < $1.version }) {
            if (jvm.version < 16 && needsJava16)
            || (jvm.version < 17 && needsJava17)
            || (jvm.version < 21 && needsJava21) {
                continue
            }
            
            suitableJava = jvm
            
            if jvm.callMethod == .direct {
                break
            }
        }
        
        if suitableJava == nil {
            warn("未找到可用 Java")
            debug("版本: \(version.getDisplayName())")
            debug("需要 Java 16: \(needsJava16)")
            debug("需要 Java 17: \(needsJava21)")
            debug("需要 Java 21: \(needsJava21)")
        }
        
        return suitableJava
    }
    
    public func run() async {
        MinecraftLauncher.launch(self)
    }
}

public struct MinecraftConfig: Codable {
    public let name: String
    public var javaPath: String!
    
    public init(name: String, javaPath: String? = nil) {
        self.name = name
        self.javaPath = javaPath
    }
}

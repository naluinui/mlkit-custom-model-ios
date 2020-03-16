import Foundation
import AVFoundation

class AudioEngine {
    
    private let internalAudioEngine = AVAudioEngine()
    
    private let sampleRate: Int
    private let windowLengthSamples: Int
    
    private var buffer: [Float]
    
    init(sampleRate: Int = 44100, windowLengthSeconds: Double = 1) {
        self.sampleRate = sampleRate
        windowLengthSamples = Int(Double(sampleRate) * windowLengthSeconds)
        buffer = Array(repeating: 0, count: windowLengthSamples)
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            print("Permission granted")
            completion(true)
        case AVAudioSessionRecordPermission.denied:
            print("Pemission denied")
            completion(false)
        case AVAudioSessionRecordPermission.undetermined:
            print("Requesting permission")
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
        @unknown default:
            completion(false)
        }
    }
    
    func start(onBufferUpdated: @escaping ([Float]) -> Void) {
        let input = internalAudioEngine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(sampleRate), channels: 1, interleaved: true)!
        let formatConverter =  AVAudioConverter(from: inputFormat, to: outputFormat)!
        
        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(sampleRate*2), format: inputFormat) { (incomingBuffer, time) in
             
            DispatchQueue.global(qos: .background).async {
            
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate * 2.0))
                var error: NSError? = nil
             
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return incomingBuffer
                }
             
                formatConverter.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
             
                if error != nil {
                    print(error!.localizedDescription)
                }
                else if let channelData = pcmBuffer!.int16ChannelData {
               
                    let channelDataPointer = channelData.pointee
                    self.buffer = stride(from: 0, to: self.windowLengthSamples, by: 1).map { Float(channelDataPointer[$0]) / 32768.0 }
                    onBufferUpdated(self.buffer)
                }
            }
        }
        
        do {
            try internalAudioEngine.start()
        } catch let error as NSError {
            print("Got an error starting audioEngine: \(error.domain), \(error)")
        }
    }
    
    func stop() {
        guard internalAudioEngine.isRunning else {
            return
        }
        internalAudioEngine.inputNode.removeTap(onBus: 0)
        internalAudioEngine.stop()
    }
    
    var isRunning: Bool {
        return internalAudioEngine.isRunning
    }
    
    func save(fileURL: URL, completion: @escaping (Bool) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            let outputFormatSettings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVSampleRateKey: Float64(self.sampleRate),
                AVNumberOfChannelsKey: 1] as [String : Any]

            let audioFile = try? AVAudioFile(forWriting: fileURL, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
            let bufferFormat = AVAudioFormat(settings: outputFormatSettings)!

            let outputBuffer = AVAudioPCMBuffer(pcmFormat: bufferFormat, frameCapacity: AVAudioFrameCount(self.buffer.count))!

            for i in 0..<self.buffer.count {
                outputBuffer.floatChannelData!.pointee[i] = self.buffer[i]
            }
            outputBuffer.frameLength = AVAudioFrameCount(self.buffer.count)

            do {
                try audioFile?.write(from: outputBuffer)
            } catch let error as NSError {
                print("error:", error.localizedDescription)
                completion(false)
            }
            
            completion(true)
        }
    }
}

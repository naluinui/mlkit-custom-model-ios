import Foundation
import AVFoundation

class AudioEngine {
    let audioEngine = AVAudioEngine()
    
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
        let input = audioEngine.inputNode
//        input.installTap( onBus: 0,         // mono input
//                              bufferSize: 44100, // a request, not a guarantee
//                              format: nil,      // no format translation
//                              block: { buffer, when in
//
//            // This block will be called over and over for successive buffers
//            // of microphone data until you stop() AVAudioEngine
//            let actualSampleCount = Int(buffer.frameLength)
//
//            print("samples \(actualSampleCount)")
//            // buffer.floatChannelData?.pointee[n] has the data for point n
//            var i=0
//            while (i < actualSampleCount) {
//                let val = buffer.floatChannelData?.pointee[i]
//                // do something to each sample here...
//                i += 1
//            }
//        })
        
//        let downMixer = AVAudioMixerNode()
//        let main = audioEngine.mainMixerNode
//
//        let format = input.inputFormat(forBus: 0)
//        let format16KHzMono = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 8000, channels: 1, interleaved: true)
//
//        audioEngine.attach(downMixer)
//        downMixer.installTap(onBus: 0, bufferSize: 640, format: format16KHzMono) { (buffer, time) -> Void in
//            do{
//                print(buffer.description)
//                if let channel1Buffer = buffer.int16ChannelData?[0] {
//                    // print(channel1Buffer[0])
//
//                }
//            }
//        }
//
//        audioEngine.connect(input, to: downMixer, format: format)
//        audioEngine.connect(downMixer, to: main, format: format16KHzMono)
//        audioEngine.prepare()

        let inputFormat = input.outputFormat(forBus: 0)
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(16000), channels: 1, interleaved: true)!
        let formatConverter =  AVAudioConverter(from: inputFormat, to: outputFormat)!
        
        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(32000), format: inputFormat) { (buffer, time) in
          
            DispatchQueue.global(qos: .background).async {
             
                 let pcmBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate * 2.0))
                 var error: NSError? = nil
                 
                 let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
                   outStatus.pointee = AVAudioConverterInputStatus.haveData
                   return buffer
                 }
                 
                
                 formatConverter.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
                 
                 if error != nil {
                    print(error!.localizedDescription)
                 }
                 else if let channelData = pcmBuffer!.int16ChannelData {
                   
                    let channelDataPointer = channelData.pointee
                    let channelData = stride(from: 0, to: 15600, by: buffer.stride).map { Float(channelDataPointer[$0]) / 32768.0 }
                    onBufferUpdated(channelData)
                 }
            }
            
        }
        
        do {
            try audioEngine.start()
        } catch let error as NSError {
            print("Got an error starting audioEngine: \(error.domain), \(error)")
        }
    }
    
    func stop() {
        audioEngine.stop()
    }
    
    var isRunning: Bool {
        return audioEngine.isRunning
    }
}

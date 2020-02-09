import AVFoundation
import UIKit

class AudioViewController: UIViewController {

    @IBOutlet var microphoneButton: UIButton!
    @IBOutlet var outputLabel: UILabel!
    
    let yamnet = YamnetInterpreter()
    let recorder = AudioEngine()
    let labels = Labels()

    override func viewDidLoad() {
        super.viewDidLoad()

        yamnet.prepare()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        recorder.requestPermission { (granted) in
            self.microphoneButton.isEnabled = granted
        }
    }
    
    @IBAction func microphonePressed() {
        if recorder.isRunning {
            recorder.stop()
        }
        else {
            recorder.start { rawFloats in
                self.yamnet.run(rawFloats) { scoresOrNil in
                    guard let scores = scoresOrNil else {
                        return
                    }
                    let top = scores[0]
                    guard let label = self.labels.get(index: top.index) else {
                        return
                    }
                    self.outputLabel.text = "\(label.text) (\(top.index)) \(top.value)"
                }
            }
        }
    }
    
    @IBAction func buttonPressed() {
        
        let url = Bundle.main.url(forResource: "dog_975ms", withExtension: "wav")!
        let waveform = readWav(url: url, length: yamnet.numOfSamples)
        
        yamnet.run(waveform) { scoresOrNil in
            guard let scores = scoresOrNil else {
                return
            }
            let top = scores[0]
            self.outputLabel.text = "\(top.label) (\(top.index)) \(top.value)"
        }
    }
}


private func readWav(url: URL, length: Int) -> [Float] {
    let file = try! AVAudioFile(forReading: url)
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)!

    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length))!
    try! file.read(into: buffer)
    
    return Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count:Int(buffer.frameLength)))
}
//
//private func readMicrophone() {
//    let engine = AVAudioEngine()
//    let input = engine.inputNode
//    let bus = 0
//    let inputFormat = input.inputFormat(forBus: bus)
//
//    engine.attach(input)
//
//    let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: false)!
//    engine.connect(input, to: engine.mainMixerNode, format: fmt)
//
//    let converter = AVAudioConverter(from: inputFormat, to: fmt)!
//
//    input.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { (buffer, time) -> Void in
//        let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
//            outStatus.pointee = AVAudioConverterInputStatus.haveData
//            return buffer
//        }
//
//        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(fmt.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!
//
//        var error: NSError? = nil
//        let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
//        assert(status != .error)
//
//        print(convertedBuffer.format)
//        print(convertedBuffer.floatChannelData)
//        print(convertedBuffer.format.streamDescription.pointee.mBytesPerFrame)
////        self.player.scheduleBuffer(convertedBuffer)
//    }
//
//}

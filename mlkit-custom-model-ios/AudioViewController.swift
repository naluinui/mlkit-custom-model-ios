import AVFoundation
import UIKit

class AudioViewController: UIViewController {

    @IBOutlet var microphoneSwitch: UISwitch!
    @IBOutlet var tableView: UITableView!
    
    let yamnet = YamnetInterpreter()
    let recorder = AudioEngine(sampleRate: 16000, windowLengthSeconds: 0.975)
    
    var scores: [Score] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        yamnet.prepare()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        recorder.requestPermission { (granted) in
            self.microphoneSwitch.isEnabled = granted
        }
    }
    
    @IBAction func microphoneToggled() {
        if recorder.isRunning {
            recorder.stop()
        }
        else {
            recorder.start { rawFloats in
                self.yamnet.run(rawFloats) { scoresOrNil in
                    if let scores = scoresOrNil, scores.count > 0 {
                        self.scores = scores
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func savePressed() {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempFileURL = tempDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString + ".wav")
        print("Saving \(tempFileURL)")
        
        recorder.save(fileURL: tempFileURL) { (success) in
            print("Done")
            
        }
    }
    
    @IBAction func buttonPressed() {
        
        let url = Bundle.main.url(forResource: "dog_975ms", withExtension: "wav")!
        let waveform = readWav(url: url, length: yamnet.numOfSamples)
        
        yamnet.run(waveform) { scoresOrNil in
            self.scores = scoresOrNil ?? []
            self.tableView.reloadData()
        }
    }
}

extension AudioViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let score = scores[indexPath.row]
        cell.textLabel?.text = score.label
        cell.detailTextLabel?.text = String(format: "%.4f", arguments: [score.value])
        return cell
    }
}


private func readWav(url: URL, length: Int) -> [Float] {
    let file = try! AVAudioFile(forReading: url)
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)!

    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length))!
    try! file.read(into: buffer)
    
    return Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count:Int(buffer.frameLength)))
}

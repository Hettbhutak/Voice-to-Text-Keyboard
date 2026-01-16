import UIKit
import AVFoundation

class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    private var recordButton: RecordButton!
    private var statusLabel: UILabel!
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Recording state
    private enum RecordingState {
        case idle
        case recording
        case processing
        case error(String)
    }
    
    private var currentState: RecordingState = .idle {
        didSet {
            updateUI(for: currentState)
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioSession()
        feedbackGenerator.prepare()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Record Button
        recordButton = RecordButton(frame: .zero)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        
        // Add gesture recognizers
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.1
        recordButton.addGestureRecognizer(longPress)
        
        // Status Label
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "Hold to record"
        view.addSubview(statusLabel)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 120),
            recordButton.heightAnchor.constraint(equalToConstant: 120),
            
            statusLabel.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Set keyboard height
        let heightConstraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 280
        )
        heightConstraint.priority = .required
        view.addConstraint(heightConstraint)
    }
    
    // MARK: - Audio Setup
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Recording Control
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startRecording()
        case .ended, .cancelled:
            stopRecording()
        default:
            break
        }
    }
    
    private func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.beginRecording()
                } else {
                    self?.currentState = .error("Microphone permission denied")
                }
            }
        }
    }
    
    private func beginRecording() {
        feedbackGenerator.impactOccurred()
        
        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        audioFileURL = tempDir.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // Audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
            audioRecorder?.record()
            currentState = .recording
        } catch {
            currentState = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        guard audioRecorder?.isRecording == true else { return }
        
        audioRecorder?.stop()
        feedbackGenerator.impactOccurred()
        currentState = .processing
        
        // Send to transcription
        if let url = audioFileURL {
            transcribeAudio(fileURL: url)
        }
    }
    
    // MARK: - Transcription
    private func transcribeAudio(fileURL: URL) {
        guard let audioData = try? Data(contentsOf: fileURL) else {
            currentState = .error("Failed to read audio file")
            return
        }
        
        // Groq API Configuration
        let apiKey = "YOUR_GROQ_API_KEY" // Replace with your API key
        let apiURL = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        request.timeoutInterval = 30
        
        // Make request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleTranscriptionResponse(data: data, response: response, error: error)
            }
        }.resume()
    }
    
    private func handleTranscriptionResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            currentState = .error("Network error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            currentState = .error("No data received")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                insertTranscribedText(text)
                currentState = .idle
            } else {
                currentState = .error("Invalid response format")
            }
        } catch {
            currentState = .error("Failed to parse response")
        }
        
        // Clean up audio file
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func insertTranscribedText(_ text: String) {
        textDocumentProxy.insertText(text)
        feedbackGenerator.impactOccurred(intensity: 0.7)
    }
    
    // MARK: - UI Updates
    private func updateUI(for state: RecordingState) {
        switch state {
        case .idle:
            recordButton.setState(.idle)
            statusLabel.text = "Hold to record"
            statusLabel.textColor = .secondaryLabel
            
        case .recording:
            recordButton.setState(.recording)
            statusLabel.text = "Recording..."
            statusLabel.textColor = .systemRed
            
        case .processing:
            recordButton.setState(.processing)
            statusLabel.text = "Processing..."
            statusLabel.textColor = .systemBlue
            
        case .error(let message):
            recordButton.setState(.idle)
            statusLabel.text = message
            statusLabel.textColor = .systemRed
            
            // Reset to idle after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if case .error = self?.currentState {
                    self?.currentState = .idle
                }
            }
        }
    }
}

// MARK: - Custom Record Button
class RecordButton: UIView {
    
    enum State {
        case idle
        case recording
        case processing
    }
    
    private let circleLayer = CAShapeLayer()
    private let pulseLayer = CAShapeLayer()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let micImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayers() {
        // Circle background
        circleLayer.fillColor = UIColor.systemBlue.cgColor
        circleLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        circleLayer.lineWidth = 3
        layer.addSublayer(circleLayer)
        
        // Pulse layer
        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.strokeColor = UIColor.systemRed.withAlphaComponent(0.5).cgColor
        pulseLayer.lineWidth = 4
        pulseLayer.opacity = 0
        layer.addSublayer(pulseLayer)
        
        // Microphone icon
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        micImageView.image = UIImage(systemName: "mic.fill", withConfiguration: config)
        micImageView.tintColor = .white
        micImageView.contentMode = .scaleAspectFit
        addSubview(micImageView)
        
        // Activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        addSubview(activityIndicator)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let circlePath = UIBezierPath(ovalIn: bounds)
        circleLayer.path = circlePath.cgPath
        pulseLayer.path = circlePath.cgPath
        
        micImageView.frame = bounds.insetBy(dx: 30, dy: 30)
        activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func setState(_ state: State) {
        switch state {
        case .idle:
            stopPulseAnimation()
            activityIndicator.stopAnimating()
            micImageView.isHidden = false
            circleLayer.fillColor = UIColor.systemBlue.cgColor
            
        case .recording:
            startPulseAnimation()
            activityIndicator.stopAnimating()
            micImageView.isHidden = false
            circleLayer.fillColor = UIColor.systemRed.cgColor
            
        case .processing:
            stopPulseAnimation()
            activityIndicator.startAnimating()
            micImageView.isHidden = true
            circleLayer.fillColor = UIColor.systemBlue.cgColor
        }
    }
    
    private func startPulseAnimation() {
        pulseLayer.opacity = 1
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.3
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.8
        opacityAnimation.toValue = 0.0
        
        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opacityAnimation]
        group.duration = 1.0
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseLayer.add(group, forKey: "pulse")
    }
    
    private func stopPulseAnimation() {
        pulseLayer.removeAllAnimations()
        pulseLayer.opacity = 0
    }
}
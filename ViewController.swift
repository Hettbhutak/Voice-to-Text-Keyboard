import UIKit

class ViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let instructionsLabel = UILabel()
    private let openSettingsButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "🎤 Voice Keyboard"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Instructions
        instructionsLabel.numberOfLines = 0
        instructionsLabel.font = UIFont.systemFont(ofSize: 16)
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let instructionsText = """
        Welcome to Voice Keyboard!
        
        To use this keyboard, follow these steps:
        
        1️⃣ Enable the Keyboard
        • Open Settings app
        • Go to General → Keyboard → Keyboards
        • Tap "Add New Keyboard..."
        • Select "VoiceKeyboard"
        
        2️⃣ Allow Full Access
        • Tap "VoiceKeyboard" in the keyboards list
        • Toggle ON "Allow Full Access"
        • This is required for microphone access
        
        3️⃣ Use the Keyboard
        • Open any app with text input
        • Tap in a text field
        • Tap the 🌐 globe icon
        • Select "VoiceKeyboard"
        
        4️⃣ Record Your Voice
        • Press and HOLD the microphone button
        • Speak clearly
        • Release when done
        • Wait for transcription (2-3 seconds)
        
        Tips:
        • Speak in a quiet environment
        • Hold the button the entire time you're speaking
        • Keep recordings under 30 seconds for best results
        • Ensure you have internet connection
        
        Troubleshooting:
        • If microphone doesn't work, check Settings → Privacy → Microphone
        • Make sure "Allow Full Access" is enabled
        • Restart the app if keyboard doesn't appear
        
        Privacy:
        • Audio is only sent to Groq API for transcription
        • No recordings are stored permanently
        • Files are deleted immediately after transcription
        """
        
        instructionsLabel.text = instructionsText
        contentView.addSubview(instructionsLabel)
        
        // Open Settings Button
        openSettingsButton.setTitle("Open Keyboard Settings", for: .normal)
        openSettingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        openSettingsButton.backgroundColor = .systemBlue
        openSettingsButton.setTitleColor(.white, for: .normal)
        openSettingsButton.layer.cornerRadius = 12
        openSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        openSettingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        contentView.addSubview(openSettingsButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            openSettingsButton.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 30),
            openSettingsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            openSettingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            openSettingsButton.heightAnchor.constraint(equalToConstant: 50),
            openSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    @objc private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
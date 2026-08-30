Add-Type -AssemblyName System.Speech
$voiceDir = "D:\GodotProjects\The Last Resonance\assets\audio\voice"
if (-not (Test-Path $voiceDir)) { New-Item -ItemType Directory -Path $voiceDir -Force }

function Save-TTS($filename, $text, $voiceName = "Microsoft Zira Desktop", $rate = 0) {
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    try {
        $synth.SelectVoice($voiceName)
    } catch {
        $synth.SelectVoice("Microsoft David Desktop")
    }
    $synth.Rate = $rate
    $outPath = Join-Path $voiceDir $filename
    $synth.SetOutputToWaveFile($outPath)
    $synth.Speak($text)
    $synth.SetOutputToNull()
    $synth.Dispose()
    Write-Host "Generated: $outPath"
}

Save-TTS "voice_ch1_eva_intro_msg.wav" "Signal acquired. I am EVA, the central administrator intelligence of Asteria. Asteria has remained dark for three hundred and twenty seven years. Thank you for awakening, K7." "Microsoft Zira Desktop" 0

import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit
import AudioKit

/// Main AUv3 Audio Unit class for the Digitakt instrument.
/// Handles MIDI input, audio rendering, and parameter management.
public class DigitaktAUv3AudioUnit: AUAudioUnit {

    var engine: AVAudioEngine!
    var conductor: Conductor!
    var paramTree = AUParameterTree()
    private var confirmEngineStarted = false
    private var doneLoading = false

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        conductor = Conductor()
        engine = conductor.engine.avEngine

        do {
            try super.init(componentDescription: componentDescription, options: options)
            try setOutputBusArrays()
        } catch {
            Log("Could not init audio unit: \(error)")
            throw error
        }

        setupParamTree()
        setInternalRenderingBlock()
        log(componentDescription)
    }

    public func setupParamTree() {
        // Empty parameter tree for now
        // Phase 1E will add filter and envelope parameters
        parameterTree = AUParameterTree.createTree(withChildren: [])
    }

    private func handleEvents(eventsList: AURenderEvent?, timestamp: UnsafePointer<AudioTimeStamp>) {
        var nextEvent = eventsList
        while nextEvent != nil {
            if nextEvent!.head.eventType == .MIDI {
                handleMIDI(midiEvent: nextEvent!.MIDI, timestamp: timestamp)
            } else if (nextEvent!.head.eventType == .parameter || nextEvent!.head.eventType == .parameterRamp) {
                handleParameter(parameterEvent: nextEvent!.parameter, timestamp: timestamp)
            }
            nextEvent = nextEvent!.head.next?.pointee
        }
    }

    private func setInternalRenderingBlock() {
        self._internalRenderBlock = { [weak self] (actionFlags, timestamp, frameCount, outputBusNumber,
            outputData, renderEvent, pullInputBlock) in
            guard let self = self else { return 1 }
            if let eventList = renderEvent?.pointee {
                self.handleEvents(eventsList: eventList, timestamp: timestamp)
            }

            // Render audio using the engine
            _ = self.engine.manualRenderingBlock(frameCount, outputData, nil)
            return noErr
        }
    }

    private func log(_ acd: AudioComponentDescription) {
        let info = ProcessInfo.processInfo
        print("\nProcess Name: \(info.processName) PID: \(info.processIdentifier)\n")

        let message = """
        Digitakt AUv3 (
                  type: \(acd.componentType.stringValue)
               subtype: \(acd.componentSubType.stringValue)
          manufacturer: \(acd.componentManufacturer.stringValue)
                 flags: \(String(format: "%#010x", acd.componentFlags))
        )
        """
        print(message)
    }

    override public func allocateRenderResources() throws {
        do {
            try engine.enableManualRenderingMode(.offline, format: outputBus.format, maximumFrameCount: 4096)
            engineStart()

            try super.allocateRenderResources()
            confirmEngineStarted = false
            doneLoading = true
        } catch {
            Log("Failed to allocate render resources: \(error)")
            return
        }
        self.mcb = self.musicalContextBlock
        self.tsb = self.transportStateBlock
        self.moeb = self.midiOutputEventBlock
    }

    func engineStart() {
        self.conductor.start()
    }

    override public func deallocateRenderResources() {
        engine.stop()
        confirmEngineStarted = false
        super.deallocateRenderResources()
        self.mcb = nil
        self.tsb = nil
        self.moeb = nil
    }

    private func handleParameter(parameterEvent event: AUParameterEvent, timestamp: UnsafePointer<AudioTimeStamp>) {
        parameterTree?.parameter(withAddress: event.parameterAddress)?.value = event.value
    }

    private func handleMIDI(midiEvent event: AUMIDIEvent, timestamp: UnsafePointer<AudioTimeStamp>) {
        let diff = Float64(event.eventSampleTime) - timestamp.pointee.mSampleTime
        let offset = MIDITimeStamp(UInt32(max(0, diff)))
        let midiEvent = MIDIEvent(data: [event.data.0, event.data.1, event.data.2])
        guard let statusType = midiEvent.status?.type else { return }

        // MIDI handling - will be expanded in Phase 1B when voice engine is added
        if statusType == .noteOn {
            let velocity = midiEvent.data[2]
            if velocity == 0 {
                receivedMIDINoteOff(noteNumber: event.data.1, channel: midiEvent.channel ?? 0, offset: offset)
            } else {
                receivedMIDINoteOn(noteNumber: event.data.1, velocity: velocity,
                                   channel: midiEvent.channel ?? 0, offset: offset)
            }
        } else if statusType == .noteOff {
            receivedMIDINoteOff(noteNumber: event.data.1, channel: midiEvent.channel ?? 0, offset: offset)
        }
    }

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel,
                            offset: MIDITimeStamp) {
        if !doneLoading { return }

        if !confirmEngineStarted && !engine.isRunning {
            engineStart()
        } else {
            confirmEngineStarted = true
        }

        // Voice playback will be added in Phase 1B
        Log("MIDI Note On: \(noteNumber) velocity: \(velocity)")
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, channel: MIDIChannel, offset: MIDITimeStamp) {
        // Voice note-off will be added in Phase 1B
        Log("MIDI Note Off: \(noteNumber)")
    }

    public override var canProcessInPlace: Bool {
        return true
    }

    var mcb: AUHostMusicalContextBlock?
    var tsb: AUHostTransportStateBlock?
    var moeb: AUMIDIOutputEventBlock?

    open var _parameterTree: AUParameterTree!
    override open var parameterTree: AUParameterTree? {
        get { return self._parameterTree }
        set { _parameterTree = newValue }
    }

    open var _internalRenderBlock: AUInternalRenderBlock!
    override open var internalRenderBlock: AUInternalRenderBlock {
        return self._internalRenderBlock
    }

    var outputBus: AUAudioUnitBus!
    open var _outputBusArray: AUAudioUnitBusArray!
    override open var outputBusses: AUAudioUnitBusArray {
        return self._outputBusArray
    }

    open func setOutputBusArrays() throws {
        let defaultAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        outputBus = try AUAudioUnitBus(format: defaultAudioFormat!)
        self._outputBusArray = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus])
    }

    override open func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
        return IndexSet(0..<availableViewConfigurations.count)
    }
}

extension FourCharCode {
    var stringValue: String {
        let value = CFSwapInt32BigToHost(self)
        let bytes = [0, 8, 16, 24].map { UInt8(value >> $0 & 0x000000FF) }
        guard let result = String(bytes: bytes, encoding: .macOSRoman) else {
            return "fail"
        }
        return result
    }
}

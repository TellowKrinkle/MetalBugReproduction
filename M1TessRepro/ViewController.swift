import Cocoa
import MetalKit

class ViewController: NSViewController {
	var renderer: Renderer!
	var devices: [MTLDevice] = []
	@IBOutlet weak var mtkview: MTKView!

	@IBOutlet weak var pass1Selector: NSPopUpButton!
	@IBOutlet weak var pass1Tess: NSButton!
	@IBOutlet weak var pass2Selector: NSPopUpButton!
	@IBOutlet weak var pass2Tess: NSButton!
	@IBOutlet weak var gpuSelector: NSPopUpButton!
	@IBOutlet weak var modelSelector: NSPopUpButton!
	@IBOutlet weak var fovSlider: NSSlider!

	static func initDropDown<T: DropDownOption>(_ selector: NSPopUpButton, for type: T.Type) {
		selector.removeAllItems()
		selector.addItems(withTitles: (0..<T.allCases.count).map { T(rawValue: $0)!.name })
		selector.selectItem(at: 0)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		devices = MTLCopyAllDevices()
		gpuSelector.removeAllItems()
		gpuSelector.addItems(withTitles: devices.map({ $0.name }))
		if let dev = MTLCreateSystemDefaultDevice() {
			gpuSelector.selectItem(withTitle: dev.name)
		}
		gpuChanged(self)
		Self.initDropDown(pass1Selector, for: VertexOrder.self)
		Self.initDropDown(pass2Selector, for: VertexOrder.self)
		Self.initDropDown(modelSelector, for: Model.self)
		pass1Tess.state = .on
		pass2Tess.state = .off
		optionsChanged(self)
	}

	override var representedObject: Any? {
		didSet {
		}
	}

	@IBAction func gpuChanged(_ sender: Any) {
		let gpu = devices[gpuSelector.indexOfSelectedItem]
		mtkview.device = gpu
		let renderer = try! Renderer(device: gpu, view: mtkview)
		self.renderer = renderer
		mtkview.delegate = renderer
		optionsChanged(sender)
	}

	@IBAction func optionsChanged(_ sender: Any) {
		renderer.config = RendererConfig(
			pass0: VertexOrder(rawValue: pass1Selector.indexOfSelectedItem)!,
			pass1: VertexOrder(rawValue: pass2Selector.indexOfSelectedItem)!,
			tess0: pass1Tess.state == .on,
			tess1: pass2Tess.state == .on,
			model: Model(rawValue: modelSelector.indexOfSelectedItem)!,
			fov: fovSlider.floatValue / 180 * .pi
		)
		fovSlider.isEnabled = renderer.config.model != .surface
	}
}


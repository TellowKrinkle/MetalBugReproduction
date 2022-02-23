import Foundation
import MetalKit

let verticesSurface: [UInt32] = [
	0x420A6778, 0x4024FE00, 0xC18B00F0, 0x3F800000,
	0x41D543E4, 0x41F231D0, 0xC1FA6150, 0x3F800000,
	0x40668F40, 0xC09099A0, 0xC15CEE40, 0x3F800000,
	0x40668F40, 0xC09099A0, 0xC15CEE40, 0x3F800000,
	0x4138B9E8, 0xC200DC40, 0x3DE93C00, 0x3F800000,
	0x420A6778, 0x4024FE00, 0xC18B00F0, 0x3F800000,
	0x4138B9E8, 0xC200DC40, 0x3DE93C00, 0x3F800000,
	0x40668F40, 0xC09099A0, 0xC15CEE40, 0x3F800000,
	0xC1DB2B28, 0xC139D920, 0xC123DA90, 0x3F800000,
	0x41D543E4, 0x41F231D0, 0xC1FA6150, 0x3F800000,
	0xC08AE490, 0x41B96BB0, 0xC1DDD770, 0x3F800000,
	0x40668F40, 0xC09099A0, 0xC15CEE40, 0x3F800000,
	0x40668F40, 0xC09099A0, 0xC15CEE40, 0x3F800000,
	0xC08AE490, 0x41B96BB0, 0xC1DDD770, 0x3F800000,
	0xC1DB2B28, 0xC139D920, 0xC123DA90, 0x3F800000,
	0xC08AE490, 0x41B96BB0, 0xC1DDD770, 0x3F800000,
	0xC20D5B1A, 0x4180A590, 0xC1C14DA0, 0x3F800000,
	0xC1DB2B28, 0xC139D920, 0xC123DA90, 0x3F800000,
]

let matrixSurface: [UInt32] = [
	0x3FAF28B9, 0x00000000, 0x00000000, 0x00000000,
	0x00000000, 0x401BB26C, 0x00000000, 0x00000000,
	0x00000000, 0x00000000, 0xBF8001A3, 0xBDCCCF6B,
	0x00000000, 0x00000000, 0xBF800000, 0x00000000,
]

let verticesCube: [Float] = [
	-1, -1, -1, 8/8, -1,  1, -1, 8/8, -1,  1,  1, 8/8,
	-1,  1,  1, 8/8, -1, -1,  1, 8/8, -1, -1, -1, 8/8,
	-1, -1, -1, 7/8,  1, -1, -1, 7/8,  1,  1, -1, 7/8,
	 1,  1, -1, 7/8, -1,  1, -1, 7/8, -1, -1, -1, 7/8,
	-1, -1, -1, 6/8, -1, -1,  1, 6/8,  1, -1,  1, 6/8,
	 1, -1,  1, 6/8,  1, -1, -1, 6/8, -1, -1, -1, 6/8,
	 1,  1,  1, 5/8, -1,  1,  1, 5/8, -1,  1, -1, 5/8,
	-1,  1, -1, 5/8,  1,  1, -1, 5/8,  1,  1,  1, 5/8,
	 1,  1,  1, 4/8,  1, -1,  1, 4/8, -1, -1,  1, 4/8,
	-1, -1,  1, 4/8, -1,  1,  1, 4/8,  1,  1,  1, 4/8,
	 1,  1,  1, 3/8,  1,  1, -1, 3/8,  1, -1, -1, 3/8,
	 1, -1, -1, 3/8,  1, -1,  1, 3/8,  1,  1,  1, 3/8,
]

func rotation(around axis: SIMD3<Float>, angle: Float) -> simd_float4x4 {
	let c = cos(angle)
	let ci = 1 - c
	let s = sin(angle)
	let x = axis.x
	let y = axis.y
	let z = axis.z
	return simd_float4x4(
		SIMD4(x * x * ci + c,     y * x * ci + z * s, x * z * ci - y * s, 0),
		SIMD4(x * y * ci - z * s, y * y * ci + c,     y * z * ci + x * s, 0),
		SIMD4(x * z * ci + y * s, y * z * ci - x * s, z * z * ci + c,     0),
		SIMD4(0,                  0,                  0,                  1)
	)
}

func translation(_ vector: SIMD3<Float>) -> simd_float4x4 {
	var matrix = simd_float4x4(1)
	matrix[3, 0] = vector.x
	matrix[3, 1] = vector.y
	matrix[3, 2] = vector.z
	return matrix
}

func lookAt(eye: SIMD3<Float>, at: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
	let f = normalize(at - eye)
	let s = normalize(cross(up, f))
	let u = cross(f, s)
	return simd_float4x4(
		SIMD4(s.x, u.x, f.x, 0),
		SIMD4(s.y, u.y, f.y, 0),
		SIMD4(s.z, u.z, f.z, 0),
		SIMD4(  0,   0,   0, 1)
	) * translation(-eye)
}

let maxPatches = 12
let indexOffset = maxPatches * 3

protocol DropDownOption: RawRepresentable, CaseIterable where RawValue == Int {
	var name: String { get }
}

enum VertexOrder: Int, DropDownOption {
	case v012 = 0
	case v120
	case v201
	case v021
	case v102
	case v210
	var offsets: SIMD3<UInt16> {
		switch self {
		case .v012: return SIMD3<UInt16>(0, 1, 2)
		case .v120: return SIMD3<UInt16>(1, 2, 0)
		case .v201: return SIMD3<UInt16>(2, 0, 1)
		case .v021: return SIMD3<UInt16>(0, 2, 1)
		case .v102: return SIMD3<UInt16>(1, 0, 2)
		case .v210: return SIMD3<UInt16>(2, 1, 0)
		}
	}
	var name: String {
		switch self {
		case .v012: return "012"
		case .v120: return "120"
		case .v201: return "201"
		case .v021: return "021"
		case .v102: return "102"
		case .v210: return "210"
		}
	}
	var winding: MTLWinding {
		switch self {
		case .v012: return .counterClockwise
		case .v120: return .counterClockwise
		case .v201: return .counterClockwise
		case .v021: return .clockwise
		case .v102: return .clockwise
		case .v210: return .clockwise
		}
	}
}

enum Model: Int, DropDownOption {
	case surface = 0
	case cube

	var name: String {
		switch self {
		case .surface: return "Surface"
		case .cube:    return "Cube"
		}
	}
}

struct RendererConfig {
	var pass0: VertexOrder
	var pass1: VertexOrder
	var tess0: Bool
	var tess1: Bool
	var model: Model
	var fov: Float
}

final class Renderer : NSObject, MTKViewDelegate {
	private let dev: MTLDevice
	private let queue: MTLCommandQueue
	private let pipelineVertex: MTLRenderPipelineState
	private let pipelineTess: MTLRenderPipelineState
	private let bufEdgeFactors: MTLBuffer
	private let bufVerticesSurface: MTLBuffer
	private let bufVerticesCube: MTLBuffer
	private let bufIndices: MTLBuffer
	private let bufMatrixSurface: MTLBuffer
	private let rpdesc: MTLRenderPassDescriptor
	private let dsWrite: MTLDepthStencilState
	private let dsLess: MTLDepthStencilState
	private let dsEqual: MTLDepthStencilState
	private let dsGreater: MTLDepthStencilState
	private var aspectRatio: Float = 1
	private var spinTransform = simd_float4x4(1)
	private var cameraTransform = simd_float4x4(1)
	public var config: RendererConfig {
		didSet {
			updateCamera()
		}
	}

	private var npatches: Int {
		switch config.model {
		case .surface: return verticesSurface.count / 12
		case .cube:    return verticesCube.count / 12
		}
	}

	private var bufVertices: MTLBuffer {
		switch config.model {
		case .surface: return bufVerticesSurface
		case .cube:    return bufVerticesCube
		}
	}

	private var colorLoadAction: MTLLoadAction {
		switch config.model {
		case .surface: return .dontCare
		case .cube:    return .clear
		}
	}

	static func createPrivateBuffer<T>(device: MTLDevice, blit: MTLBlitCommandEncoder, count: Int, type: T.Type, init initFn: (UnsafeMutableBufferPointer<T>) -> ()) -> MTLBuffer? {
		let len = count * MemoryLayout<T>.stride
		guard let upload = device.makeBuffer(length: len, options: .storageModeShared) else { return nil }
		guard let out = device.makeBuffer(length: len, options: .storageModePrivate) else { return nil }
		initFn(UnsafeMutableBufferPointer(start: upload.contents().bindMemory(to: T.self, capacity: count), count: count))
		blit.copy(from: upload, sourceOffset: 0, to: out, destinationOffset: 0, size: len)
		return out
	}

	static func createPrivateBuffer(device: MTLDevice, blit: MTLBlitCommandEncoder, data: UnsafeRawBufferPointer) -> MTLBuffer? {
		guard let upload = device.makeBuffer(bytes: data.baseAddress!, length: data.count) else { return nil }
		guard let out = device.makeBuffer(length: data.count, options: .storageModePrivate) else { return nil }
		blit.copy(from: upload, sourceOffset: 0, to: out, destinationOffset: 0, size: data.count)
		return out
	}

	static func initIndices(_ buffer: UnsafeMutableBufferPointer<UInt16>, offsets: SIMD3<UInt16>) {
		for i in stride(from: 0, to: buffer.count, by: 3) {
			buffer[i + 0] = UInt16(i) + offsets.x
			buffer[i + 1] = UInt16(i) + offsets.y
			buffer[i + 2] = UInt16(i) + offsets.z
		}
	}

	init(device: MTLDevice, view: MTKView) throws {
		dev = device
		queue = device.makeCommandQueue()!
		queue.label = "Queue"
		let lib = dev.makeDefaultLibrary()!

		config = RendererConfig(pass0: .v012, pass1: .v012, tess0: false, tess1: false, model: .surface, fov: .pi / 4)

		let dssdesc = MTLDepthStencilDescriptor()
		dssdesc.isDepthWriteEnabled = true
		dssdesc.label = "Depth Write"
		dsWrite = device.makeDepthStencilState(descriptor: dssdesc)!
		dssdesc.isDepthWriteEnabled = false
		dssdesc.depthCompareFunction = .less
		dssdesc.label = "Depth Less"
		dsLess = device.makeDepthStencilState(descriptor: dssdesc)!
		dssdesc.depthCompareFunction = .equal
		dssdesc.label = "Depth Equal"
		dsEqual = device.makeDepthStencilState(descriptor: dssdesc)!
		dssdesc.depthCompareFunction = .greater
		dssdesc.label = "Depth Greater"
		dsGreater = device.makeDepthStencilState(descriptor: dssdesc)!

		rpdesc = MTLRenderPassDescriptor()
		rpdesc.colorAttachments[0].loadAction = .clear
		rpdesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
		rpdesc.colorAttachments[0].storeAction = .store
		rpdesc.depthAttachment.loadAction = .clear
		rpdesc.depthAttachment.clearDepth = 1
		rpdesc.depthAttachment.storeAction = .dontCare

		let pdesc = MTLRenderPipelineDescriptor()
		pdesc.depthAttachmentPixelFormat = .depth32Float
		pdesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
		pdesc.vertexFunction = lib.makeFunction(name: "vs1")!
		pdesc.fragmentFunction = lib.makeFunction(name: "fs0")!
		pdesc.label = "Vertex Pipeline"
		pipelineVertex = try dev.makeRenderPipelineState(descriptor: pdesc)
		pdesc.vertexFunction = lib.makeFunction(name: "vs0")!

		let layout = pdesc.vertexDescriptor!.layouts[0]!
		layout.stride = 16
		layout.stepFunction = .perPatchControlPoint
		layout.stepRate = 1
		let attrs = pdesc.vertexDescriptor!.attributes[0]!
		attrs.offset = 0
		attrs.bufferIndex = 0
		attrs.format = .float4
		pdesc.tessellationFactorFormat = .half
		pdesc.tessellationPartitionMode = .fractionalOdd
		pdesc.tessellationFactorStepFunction = .perPatch
		pdesc.tessellationOutputWindingOrder = .counterClockwise
		pdesc.isTessellationFactorScaleEnabled = false
		pdesc.maxTessellationFactor = 64
		pdesc.label = "Tessellation Pipeline"
		pipelineTess = try dev.makeRenderPipelineState(descriptor: pdesc)

		let cbuf = queue.makeCommandBuffer()!
		let blit = cbuf.makeBlitCommandEncoder()!
		bufEdgeFactors = Self.createPrivateBuffer(device: device, blit: blit, count: 4 * maxPatches, type: UInt16.self, init: { $0.initialize(repeating: 0x3C00) })!
		bufVerticesSurface = verticesSurface.withUnsafeBytes { Self.createPrivateBuffer(device: device, blit: blit, data: $0)! }
		bufVerticesCube = verticesCube.withUnsafeBytes { Self.createPrivateBuffer(device: device, blit: blit, data: $0)! }
		bufIndices = Self.createPrivateBuffer(device: device, blit: blit, count: 6 * indexOffset, type: UInt16.self, init: { buf in
			for order in VertexOrder.allCases {
				let start = order.rawValue * indexOffset
				let end = start + indexOffset
				Self.initIndices(.init(rebasing: buf[start..<end]), offsets: order.offsets)
			}
		})!
		bufMatrixSurface = matrixSurface.withUnsafeBytes { Self.createPrivateBuffer(device: device, blit: blit, data: $0)! }
		blit.endEncoding()
		cbuf.commit()
		bufEdgeFactors.label = "Edge Factors"
		bufVerticesSurface.label = "Vertices (Surface)"
		bufVerticesCube.label = "Vertices (Cube)"
		bufIndices.label = "Indices"
		bufMatrixSurface.label = "Transformation Matrix"

		super.init()

		mtkView(view, drawableSizeWillChange: view.drawableSize)
	}

	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		let tdesc = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat: .depth32Float,
			width: Int(size.width),
			height: Int(size.height),
			mipmapped: false
		)
		tdesc.usage = .renderTarget
		if #available(macOS 11, *), dev.supportsFamily(.apple1) {
			tdesc.storageMode = .memoryless
		} else {
			tdesc.storageMode = .private
		}
		let tex = dev.makeTexture(descriptor: tdesc)!
		rpdesc.depthAttachment.texture = tex
		tex.label = "Depth Texture"

		aspectRatio = Float(size.width / size.height)
		updateCamera()
	}

	func updateCamera() {
		let far: Float = 100
		let near: Float = 0.1
		let fov: Float = tan(config.fov / 2)
		let m00 = 1 / (aspectRatio * fov)
		let m11 = 1 / fov
		let m22 = far / (far - near)
		let m23 = (-far * near) / (far - near)

		let perspective = simd_float4x4(
			SIMD4(m00,   0,   0, 0),
			SIMD4(  0, m11,   0, 0),
			SIMD4(  0,   0, m22, 1),
			SIMD4(  0,   0, m23, 0)
		)

		let camera = lookAt(
			eye: SIMD3(4, 0, 0),
			 at: SIMD3(0, 0, 0),
			 up: SIMD3(0, 1, 0)
		)

		cameraTransform = perspective * camera
	}

	func encodeDraw(_ enc: MTLRenderCommandEncoder, order: VertexOrder, tess: Bool) {
		if tess {
			enc.drawPatches(
				numberOfPatchControlPoints: 3,
				patchStart: 0,
				patchCount: npatches,
				patchIndexBuffer: nil,
				patchIndexBufferOffset: 0,
				instanceCount: 1,
				baseInstance: 0
			)
		} else {
			enc.drawIndexedPrimitives(
				type: .triangle,
				indexCount: npatches * 3,
				indexType: .uint16,
				indexBuffer: bufIndices,
				indexBufferOffset: indexOffset * MemoryLayout<UInt16>.stride * order.rawValue
			)
		}
	}

	func draw(in view: MTKView) {
		let drawable = view.currentDrawable!
		let cbuf = queue.makeCommandBuffer()!
		cbuf.label = "Draw"
		rpdesc.colorAttachments[0].texture = drawable.texture
		rpdesc.colorAttachments[0].loadAction = colorLoadAction
		let enc = cbuf.makeRenderCommandEncoder(descriptor: rpdesc)!
		enc.label = "Render"
		enc.setCullMode(.back)
		enc.setFrontFacing(config.pass0.winding)
		enc.setDepthStencilState(dsWrite)
		enc.setVertexBuffer(bufVertices, offset: 0, index: 0)
		if config.model == .surface {
			enc.setVertexBuffer(bufMatrixSurface, offset: 0, index: 1)
		} else {
			let transform = cameraTransform * spinTransform
			withUnsafeBytes(of: transform.transpose) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 1) }
		}
		withUnsafeBytes(of: 0xff000000 as UInt32) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 2) }
		if config.tess0 {
			withUnsafeBytes(of: config.pass0.offsets) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 3) }
			enc.setTessellationFactorBuffer(bufEdgeFactors, offset: 0, instanceStride: 0)
			enc.setRenderPipelineState(pipelineTess)
		} else {
			enc.setRenderPipelineState(pipelineVertex)
		}
		encodeDraw(enc, order: config.pass0, tess: config.tess0)

		if config.tess1 {
			if !config.tess0 || config.pass0 != config.pass1 {
				withUnsafeBytes(of: config.pass1.offsets) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 3) }
			}
			if !config.tess0 {
				enc.setTessellationFactorBuffer(bufEdgeFactors, offset: 0, instanceStride: 0)
				enc.setRenderPipelineState(pipelineTess)
			}
		} else {
			if config.tess0 {
				enc.setRenderPipelineState(pipelineVertex)
			}
		}
		if config.pass0.winding != config.pass1.winding {
			enc.setFrontFacing(config.pass1.winding)
		}
		enc.setDepthStencilState(dsGreater)
		withUnsafeBytes(of: 0xff0000ff as UInt32) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 2) }
		encodeDraw(enc, order: config.pass1, tess: config.tess1)
		enc.setDepthStencilState(dsEqual)
		withUnsafeBytes(of: 0xff00ff00 as UInt32) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 2) }
		encodeDraw(enc, order: config.pass1, tess: config.tess1)
		enc.setDepthStencilState(dsLess)
		withUnsafeBytes(of: 0xffff0000 as UInt32) { enc.setVertexBytes($0.baseAddress!, length: $0.count, index: 2) }
		encodeDraw(enc, order: config.pass1, tess: config.tess1)
		enc.endEncoding()
		cbuf.present(drawable)
		cbuf.commit()
		spinTransform = rotation(around: SIMD3(0.1, 1, 0.3), angle: .pi / 1024) * spinTransform
	}
}

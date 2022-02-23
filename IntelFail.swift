import Metal

for dev in MTLCopyAllDevices() {
	let lib = try dev.makeLibrary(source: """
	kernel void go(uint uid [[thread_position_in_grid]], device float* f [[buffer(0)]]) {
		if (uchar(f[uid]) & 0x80) { f[uid] = 1000; }
	}
	""", options: nil)
	let kernel = try dev.makeComputePipelineState(function: lib.makeFunction(name: "go")!)
	let buffer = dev.makeBuffer(length: 4, options: .storageModeShared)!
	buffer.contents().storeBytes(of: 128, as: Float.self)
	let q = dev.makeCommandQueue()!
	let cb = q.makeCommandBuffer()!
	let enc = cb.makeComputeCommandEncoder()!
	enc.setBuffer(buffer, offset: 0, index: 0)
	enc.setComputePipelineState(kernel)
	enc.dispatchThreads(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
	enc.endEncoding()
	cb.commit()
	cb.waitUntilCompleted()
	let result = buffer.contents().load(as: Float.self)
	print("\(dev.name): \(result) (\(result == 1000 ? "OK" : "Fail"))")
}

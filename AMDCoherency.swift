import Metal

let shader = """
kernel void cs(uint2 pos [[thread_position_in_grid]], device metal::atomic_uint* box) {
	pos += 256;
	metal::atomic_fetch_min_explicit(box + 0, pos.x, metal::memory_order_relaxed);
	metal::atomic_fetch_min_explicit(box + 1, pos.y, metal::memory_order_relaxed);
	metal::atomic_fetch_max_explicit(box + 2, pos.x, metal::memory_order_relaxed);
	metal::atomic_fetch_max_explicit(box + 3, pos.y, metal::memory_order_relaxed);
}
"""

for gpu in MTLCopyAllDevices() {
	print(gpu.name)
	let lib = try gpu.makeLibrary(source: shader, options: nil)
	let pipe = try gpu.makeComputePipelineState(function: lib.makeFunction(name: "cs")!)
	let q = gpu.makeCommandQueue()!
	let upload_cpu = gpu.makeBuffer(length: 16, options: .storageModeShared)!
	let upload_gpu = gpu.makeBuffer(length: 16, options: .storageModePrivate)!
	upload_cpu.contents().storeBytes(of: SIMD4<UInt32>(1024, 1024, 0, 0), as: SIMD4<UInt32>.self)
	let buf = gpu.makeBuffer(length: 16, options: .storageModeShared)!
	let ptr = UnsafeMutableBufferPointer(start: buf.contents().bindMemory(to: UInt32.self, capacity: 4), count: 4)
	for i in 0..<3 {
		let cb = q.makeCommandBuffer()!
		if i < 1 {
			let blit = cb.makeBlitCommandEncoder()!
			blit.copy(from: upload_cpu, sourceOffset: 0, to: upload_gpu, destinationOffset: 0, size: 16)
			blit.copy(from: upload_gpu, sourceOffset: 0, to: buf, destinationOffset: 0, size: 16)
			blit.endEncoding()
		}
		if i >= 1 {
			let enc = cb.makeComputeCommandEncoder()!
			enc.setBuffer(buf, offset: 0, index: 0)
			enc.setComputePipelineState(pipe)
			enc.dispatchThreadgroups(MTLSize(width: 16, height: 16, depth: 1), threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
			enc.endEncoding()
		}
		cb.commit()
		cb.waitUntilCompleted()
		print(ptr.map(String.init(_:)).joined(separator: " "))
	}
}

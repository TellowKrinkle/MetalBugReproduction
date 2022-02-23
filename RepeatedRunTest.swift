import Metal
import MetalKit

let dir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
let resdir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "\(dir)/Res"
let count = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1])! : 100000

let vertices = try Data(contentsOf: URL(fileURLWithPath: "\(resdir)/Vertices.hex"))
let indices = try Data(contentsOf: URL(fileURLWithPath: "\(resdir)/Indices.hex"))
let uniforms = try Data(contentsOf: URL(fileURLWithPath: "\(resdir)/Uniforms.hex"))

let attrs0: [(Int, Int, MTLVertexFormat)] = [
	(0,  0, .float3),
	(2, 12, .float3),
	(8, 24, .float2),
	(9, 32, .float2),
]

func makeVertexDescriptor(_ attrs: [(Int, Int, MTLVertexFormat)], stride: Int) -> MTLVertexDescriptor {
	let desc = MTLVertexDescriptor()
	for (idx, offset, type) in attrs {
		desc.attributes[idx].offset = offset
		desc.attributes[idx].format = type
	}
	desc.layouts[0].stride = stride
	return desc
}

let shaders = """
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wreturn-type"
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Light
{
	int4 color;
	float4 cosatt;
	float4 distatt;
	float4 pos;
	float4 dir;
};

struct VSBlock
{
	uint components;
	uint xfmem_dualTexInfo;
	uint xfmem_numColorChans;
	uint missing_color_hex;
	float4 missing_color_value;
	float4 cpnmtx[6];
	float4 cproj[4];
	int4 cmtrl[4];
	Light clights[8];
	float4 ctexmtx[24];
	float4 ctrmtx[64];
	float4 cnmtx[32];
	float4 cpostmtx[64];
	float4 cpixelcenter;
	float2 cviewport;
	uint4 xfmem_pack1[8];
	float4 ctangent;
	float4 cbinormal;
	uint vertex_stride;
	uint vertex_offset_rawnormal;
	uint vertex_offset_rawtangent;
	uint vertex_offset_rawbinormal;
	uint vertex_offset_rawpos;
	uint vertex_offset_posmtx;
	uint vertex_offset_rawcolor0;
	uint vertex_offset_rawcolor1;
	uint4 vertex_offset_rawtex[2];
};

struct VS_OUTPUT
{
	float4 pos;
	float4 colors_0;
	float4 colors_1;
	float3 tex0;
	float3 tex1;
};

struct vs_out
{
	float4 colors_0 [[user(locn0)]];
	float4 colors_1 [[user(locn1)]];
	float3 tex0 [[user(locn2)]];
	float3 tex1 [[user(locn3)]];
	float4 gl_Position [[position]];
	float gl_ClipDistance [[clip_distance]] [2];
	float gl_ClipDistance_0 [[user(clip0)]];
	float gl_ClipDistance_1 [[user(clip1)]];
};

struct vs_in
{
	float4 rawpos [[attribute(0)]];
	float3 rawnormal [[attribute(2)]];
	float2 rawtex0 [[attribute(8)]];
	float2 rawtex1 [[attribute(9)]];
};

vertex vs_out vs(vs_in in [[stage_in]], constant VSBlock& _35 [[buffer(1)]])
{
	vs_out out = {};
	float4 vertex_color_0 = _35.missing_color_value;
	float4 vertex_color_1 = _35.missing_color_value;
	float4 P0 = _35.cpnmtx[0];
	float4 P1 = _35.cpnmtx[1];
	float4 P2 = _35.cpnmtx[2];
	float3 N0 = _35.cpnmtx[3].xyz;
	float3 N1 = _35.cpnmtx[4].xyz;
	float3 N2 = _35.cpnmtx[5].xyz;
	float4 pos = float4(dot(P0, in.rawpos), dot(P1, in.rawpos), dot(P2, in.rawpos), 1.0);
	float3 rawtangent = _35.ctangent.xyz;
	float3 rawbinormal = _35.cbinormal.xyz;
	float3 _normal = fast::normalize(float3(dot(N0, in.rawnormal), dot(N1, in.rawnormal), dot(N2, in.rawnormal)));
	float3 _tangent = float3(dot(N0, rawtangent), dot(N1, rawtangent), dot(N2, rawtangent));
	float3 _binormal = float3(dot(N0, rawbinormal), dot(N1, rawbinormal), dot(N2, rawbinormal));
	VS_OUTPUT o;
	o.pos = float4(dot(_35.cproj[0], pos), dot(_35.cproj[1], pos), dot(_35.cproj[2], pos), dot(_35.cproj[3], pos));
	int4 mat = _35.cmtrl[2];
	int4 lacc = int4(255);
	lacc.w = 255;
	lacc = clamp(lacc, int4(0), int4(255));
	o.colors_0 = float4((mat * (lacc + (lacc >> int4(7)))) >> int4(8)) / float4(255.0);
	int4 mat_1 = _35.cmtrl[3];
	lacc = int4(255);
	lacc.w = 255;
	lacc = clamp(lacc, int4(0), int4(255));
	o.colors_1 = float4((mat_1 * (lacc + (lacc >> int4(7)))) >> int4(8)) / float4(255.0);
	float4 coord = float4(0.0, 0.0, 1.0, 1.0);
	coord = float4(0.0, 0.0, 1.0, 1.0);
	coord = float4(in.rawtex0.x, in.rawtex0.y, 1.0, 1.0);
	coord.z = 1.0;
	if (isnan(coord.x))
	{
		coord.x = 1.0;
	}
	if (isnan(coord.y))
	{
		coord.y = 1.0;
	}
	if (isnan(coord.z))
	{
		coord.z = 1.0;
	}
	o.tex0 = float3(dot(coord, _35.ctexmtx[0]), dot(coord, _35.ctexmtx[1]), 1.0);
	float4 P0_1 = _35.cpostmtx[61];
	float4 P1_1 = _35.cpostmtx[62];
	float4 P2_1 = _35.cpostmtx[63];
	o.tex0 = float3(dot(P0_1.xyz, o.tex0) + P0_1.w, dot(P1_1.xyz, o.tex0) + P1_1.w, dot(P2_1.xyz, o.tex0) + P2_1.w);
	if (o.tex0.z == 0.0)
	{
		float3 _295 = o.tex0;
		float2 _303 = fast::clamp(_295.xy / float2(2.0), float2(-1.0), float2(1.0));
		o.tex0.x = _303.x;
		o.tex0.y = _303.y;
	}
	coord = float4(0.0, 0.0, 1.0, 1.0);
	coord = float4(in.rawtex1.x, in.rawtex1.y, 1.0, 1.0);
	coord.z = 1.0;
	if (isnan(coord.x))
	{
		coord.x = 1.0;
	}
	if (isnan(coord.y))
	{
		coord.y = 1.0;
	}
	if (isnan(coord.z))
	{
		coord.z = 1.0;
	}
	o.tex1 = float3(dot(coord, _35.ctexmtx[3]), dot(coord, _35.ctexmtx[4]), 1.0);
	float4 P0_2 = _35.cpostmtx[61];
	float4 P1_2 = _35.cpostmtx[62];
	float4 P2_2 = _35.cpostmtx[63];
	o.tex1 = float3(dot(P0_2.xyz, o.tex1) + P0_2.w, dot(P1_2.xyz, o.tex1) + P1_2.w, dot(P2_2.xyz, o.tex1) + P2_2.w);
	if (o.tex1.z == 0.0)
	{
		float3 _384 = o.tex1;
		float2 _388 = fast::clamp(_384.xy / float2(2.0), float2(-1.0), float2(1.0));
		o.tex1.x = _388.x;
		o.tex1.y = _388.y;
	}
	o.colors_1 = float4(0.0);
	float clipDepth = o.pos.z * 0.99999988079071044921875;
	float clipDist0 = clipDepth + o.pos.w;
	float clipDist1 = -clipDepth;
	o.pos.z = (o.pos.w * _35.cpixelcenter.w) - (o.pos.z * _35.cpixelcenter.z);
	float4 _429 = o.pos;
	float2 _431 = _429.xy * sign(_35.cpixelcenter.xy * float2(1.0, -1.0));
	o.pos.x = _431.x;
	o.pos.y = _431.y;
	float4 _437 = o.pos;
	float _440 = o.pos.w;
	float2 _445 = _437.xy - (_35.cpixelcenter.xy * _440);
	o.pos.x = _445.x;
	o.pos.y = _445.y;
	out.tex0 = o.tex0;
	out.tex1 = o.tex1;
	out.colors_0 = o.colors_0;
	out.colors_1 = o.colors_1;
	out.gl_ClipDistance[0] = clipDist0;
	out.gl_ClipDistance[1] = clipDist1;
	out.gl_Position = o.pos;
	out.gl_ClipDistance_0 = out.gl_ClipDistance[0];
	out.gl_ClipDistance_1 = out.gl_ClipDistance[1];
	return out;
}

struct PSBlock
{
	int4 color[4];
	int4 k[4];
	int4 alphaRef;
	int4 texdim[8];
	int4 czbias[2];
	int4 cindscale[2];
	int4 cindmtx[6];
	int4 cfogcolor;
	int4 cfogi;
	float4 cfogf;
	float4 cfogrange[3];
	float4 czslope;
	float2 cefbscale;
	uint bpmem_genmode;
	uint bpmem_alphaTest;
	uint bpmem_fogParam3;
	uint bpmem_fogRangeBase;
	uint bpmem_dstalpha;
	uint bpmem_ztex_op;
	uint bpmem_late_ztest;
	uint bpmem_rgba6_format;
	uint bpmem_dither;
	uint bpmem_bounding_box;
	uint4 bpmem_pack1[16];
	uint4 bpmem_pack2[8];
	int4 konstLookup[32];
	uint blend_enable;
	uint blend_src_factor;
	uint blend_src_factor_alpha;
	uint blend_dst_factor;
	uint blend_dst_factor_alpha;
	uint blend_subtract;
	uint blend_subtract_alpha;
	uint logic_op_enable;
	uint logic_op_mode;
};

struct fs_out
{
	float4 real_ocol0 [[color(0)]];
};

struct fs_in
{
	float4 colors_0 [[user(locn0)]];
	float4 colors_1 [[user(locn1)]];
	float3 tex0 [[user(locn2)]];
	float3 tex1 [[user(locn3)]];
};

static inline __attribute__((always_inline))
int4 iround(thread const float4& x)
{
	return int4(round(x));
}

static inline __attribute__((always_inline))
int4 sampleTexture(thread const uint& texmap, texture2d_array<float> tex, sampler texSmplr, thread const int2& uv, thread const int& layer, constant PSBlock& v_58)
{
	float size_s = float(v_58.texdim[texmap].x * 128);
	float size_t = float(v_58.texdim[texmap].y * 128);
	float3 coords = float3(float(uv.x) / size_s, float(uv.y) / size_t, float(layer));
	uint texmode0 = v_58.bpmem_pack2[texmap].z;
	float lod_bias = float(extract_bits(int(texmode0), uint(8), uint(16))) / 256.0;
	float4 param = tex.sample(texSmplr, coords.xy, uint(round(coords.z)), bias(lod_bias)) * 255.0;
	return iround(param);
}

fragment fs_out fs(fs_in in [[stage_in]], constant PSBlock& v_58 [[buffer(0)]], float4 in_ocol0 [[color(0)]], array<texture2d_array<float>, 2> samp [[texture(0)]], array<sampler, 2> sampSmplr [[sampler(0)]], float4 gl_FragCoord [[position]], uint gl_SampleID [[sample_id]])
{
	fs_out out = {};
	gl_FragCoord.xy += get_sample_position(gl_SampleID) - 0.5;
	float4 rawpos = gl_FragCoord;
	float4 initial_ocol0 = in_ocol0;
	int layer = 0;
	int4 c0 = v_58.color[1];
	int4 c1 = v_58.color[2];
	int4 c2 = v_58.color[3];
	int4 prev = v_58.color[0];
	int4 rastemp = int4(0);
	int4 textemp = int4(0);
	int4 konsttemp = int4(0);
	int3 comp16 = int3(1, 256, 0);
	int3 comp24 = int3(1, 256, 65536);
	int alphabump = 0;
	int3 tevcoord = int3(0);
	int2 wrappedcoord = int2(0);
	int2 tempcoord = int2(0);
	int4 tevin_a = int4(0);
	int4 tevin_b = int4(0);
	int4 tevin_c = int4(0);
	int4 tevin_d = int4(0);
	float4 col0 = in.colors_0;
	float4 col1 = in.colors_1;
	float2 _182;
	if (in.tex0.z == 0.0)
	{
		_182 = in.tex0.xy;
	}
	else
	{
		_182 = in.tex0.xy / float2(in.tex0.z);
	}
	int2 fixpoint_uv0 = int2(_182 * float2(v_58.texdim[0].zw * int2(128)));
	float2 _208;
	if (in.tex1.z == 0.0)
	{
		_208 = in.tex1.xy;
	}
	else
	{
		_208 = in.tex1.xy / float2(in.tex1.z);
	}
	int2 fixpoint_uv1 = int2(_208 * float2(v_58.texdim[1].zw * int2(128)));
	int2 indtevtrans0 = int2(0);
	wrappedcoord.x = fixpoint_uv0.x;
	wrappedcoord.y = fixpoint_uv0.y;
	int2 _238 = wrappedcoord + indtevtrans0;
	tevcoord.x = _238.x;
	tevcoord.y = _238.y;
	int3 _243 = tevcoord;
	int2 _248 = (_243.xy << int2(8)) >> int2(8);
	tevcoord.x = _248.x;
	tevcoord.y = _248.y;
	float4 param = col0 * 255.0;
	rastemp = iround(param);
	uint param_1 = 0u;
	int2 param_2 = tevcoord.xy;
	int param_3 = layer;
	textemp = sampleTexture(param_1, samp[0], sampSmplr[0], param_2, param_3, v_58);
	tevin_a = int4(0);
	tevin_b = int4(textemp.xyz, 0) & int4(255);
	tevin_c = int4(c1.xyz, 0) & int4(255);
	tevin_d = int4(rastemp.xyz, 0);
	int3 _317 = clamp(tevin_d.xyz + ((((tevin_a.xyz << int3(8)) + ((tevin_b.xyz - tevin_a.xyz) * (tevin_c.xyz + (tevin_c.xyz >> int3(7))))) + int3(128)) >> int3(8)), int3(0), int3(255));
	c0.x = _317.x;
	c0.y = _317.y;
	c0.z = _317.z;
	prev.w = clamp(tevin_d.w + ((((tevin_a.w << 8) + ((tevin_b.w - tevin_a.w) * (tevin_c.w + (tevin_c.w >> 7)))) + 128) >> 8), 0, 255);
	int2 indtevtrans1 = int2(0);
	wrappedcoord.x = fixpoint_uv1.x;
	wrappedcoord.y = fixpoint_uv1.y;
	int2 _356 = wrappedcoord + indtevtrans1;
	tevcoord.x = _356.x;
	tevcoord.y = _356.y;
	int3 _361 = tevcoord;
	int2 _366 = (_361.xy << int2(8)) >> int2(8);
	tevcoord.x = _366.x;
	tevcoord.y = _366.y;
	uint param_4 = 1u;
	int2 param_5 = tevcoord.xy;
	int param_6 = layer;
	textemp = sampleTexture(param_4, samp[1], sampSmplr[1], param_5, param_6, v_58);
	tevin_a = int4(0);
	tevin_b = int4(c0.xyz, 0) & int4(255);
	tevin_c = int4(textemp.xyz, 0) & int4(255);
	tevin_d = int4(0, 0, 0, prev.w);
	int3 _428 = clamp((tevin_d.xyz << int3(1)) + (((((tevin_a.xyz << int3(8)) + ((tevin_b.xyz - tevin_a.xyz) * (tevin_c.xyz + (tevin_c.xyz >> int3(7))))) << int3(1)) + int3(128)) >> int3(8)), int3(0), int3(255));
	prev.x = _428.x;
	prev.y = _428.y;
	prev.z = _428.z;
	prev.w = clamp(tevin_d.w + ((((tevin_a.w << 8) + ((tevin_b.w - tevin_a.w) * (tevin_c.w + (tevin_c.w >> 7)))) + 128) >> 8), 0, 255);
	prev &= int4(255);
	if (prev.w == 1)
	{
		prev.w = 0;
	}
	int zCoord = int((1.0 - rawpos.z) * 16777216.0);
	zCoord = clamp(zCoord, 0, 16777215);
	float3 _483 = float3(prev.xyz) / float3(255.0);
	float4 ocol0;
	ocol0.x = _483.x;
	ocol0.y = _483.y;
	ocol0.z = _483.z;
	ocol0.w = float(prev.w >> 2) / 63.0;
	out.real_ocol0 = ocol0;
	return out;
}
"""

extension MTKTextureLoader {
	func newArrayTexture(urls: [URL], q: MTLCommandQueue) throws -> MTLTexture {
		let bases = try urls.map { try newTexture(URL: $0, options: [.SRGB: false]) }
		let mip0 = bases.max(by: { $0.width < $1.width })!
		let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: mip0.pixelFormat, width: mip0.width, height: mip0.height, mipmapped: urls.count > 1)
		desc.mipmapLevelCount = urls.count
		desc.usage = .shaderRead
		desc.storageMode = .private
		desc.textureType = .type2DArray
		let tex = device.makeTexture(descriptor: desc)!
		let cbuf = q.makeCommandBuffer()!
		let blit = cbuf.makeBlitCommandEncoder()!
		for base in bases { blit.copy(from: base, to: tex) }
		blit.endEncoding()
		cbuf.commit()
		return tex
	}
}

let mipCounts: [Int] = [
	1, 4,
	1, 5,
	1, 6,
]

let draws: [(Int, Int, Int, Int, Int, Int, Int)] = [
	(13525, 11663, 0x07062, 0x2ee00, 0x37c00, 0, 1),
	(  370, 32984, 0x143e8, 0x42000, 0x43000, 2, 3),
	(  528, 46807, 0x1c570, 0x4c800, 0x4f000, 4, 5),
]

for gpu in MTLCopyAllDevices() {
	print(gpu.name)
	let lib = try gpu.makeLibrary(source: shaders, options: nil)
	let size = MTLSizeMake(640, 448, 1)
	let linebytes = size.width * 4
	let imagebytes = linebytes * size.height
	let pdesc = MTLRenderPipelineDescriptor()
	pdesc.colorAttachments[0].pixelFormat = .rgba8Unorm
	pdesc.depthAttachmentPixelFormat = .depth32Float
	pdesc.vertexFunction = lib.makeFunction(name: "vs")!
	pdesc.fragmentFunction = lib.makeFunction(name: "fs")!
	pdesc.vertexDescriptor = makeVertexDescriptor(attrs0, stride: 40)
	let pipe = try gpu.makeRenderPipelineState(descriptor: pdesc)
	let texd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: size.width, height: size.height, mipmapped: false)
	texd.textureType = .type2DArray
	texd.usage = [.renderTarget, .shaderRead]
	texd.storageMode = .private
	let depth = (0..<4).map { _ in gpu.makeTexture(descriptor: texd)! }
	texd.pixelFormat = .rgba8Unorm
	let color = (0..<4).map { _ in gpu.makeTexture(descriptor: texd)! }

	let q = gpu.makeCommandQueue()!
	let loader = MTKTextureLoader(device: gpu)
	let textures = mipCounts.enumerated().map { (i, mips) in
		let names = mips > 1 ? (0..<mips).map { "\(resdir)/Tex\(i)M\($0).png" } : ["\(resdir)/Tex\(i).png"]
		return try! loader.newArrayTexture(urls: names.map { URL(fileURLWithPath: $0) }, q: q)
	}
	let sampd = MTLSamplerDescriptor()
	(sampd.sAddressMode, sampd.tAddressMode) = (.repeat, .repeat)
	(sampd.minFilter, sampd.magFilter, sampd.mipFilter) = (.linear, .linear, .linear)
	let samp = gpu.makeSamplerState(descriptor: sampd)!
	let uni_vertices = vertices.withUnsafeBytes { gpu.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared)! }
	let uni_indices  = indices .withUnsafeBytes { gpu.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared)! }
	let uni_uniforms = uniforms.withUnsafeBytes { gpu.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared)! }

	let rdesc = MTLRenderPassDescriptor()
	rdesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
	rdesc.colorAttachments[0].loadAction = .clear
	rdesc.colorAttachments[0].storeAction = .store
	rdesc.depthAttachment.loadAction = .clear
	rdesc.depthAttachment.clearDepth = 0
	rdesc.depthAttachment.storeAction = .dontCare
	let dssdesc = MTLDepthStencilDescriptor()
	dssdesc.depthCompareFunction = .greaterEqual
	dssdesc.isDepthWriteEnabled = true
	let dss = gpu.makeDepthStencilState(descriptor: dssdesc)!

	let lock = NSLock()
	var buffers = [MTLBuffer]()
	let sema = DispatchSemaphore(value: 20)

	let outbuf = malloc(imagebytes)!

	for i in 0..<count { autoreleasepool {
//		let capdesc = MTLCaptureDescriptor()
//		capdesc.captureObject = gpu
//		capdesc.destination = .developerTools
//		try! MTLCaptureManager.shared().startCapture(with: capdesc)

		let cbuf = q.makeCommandBuffer()!
		rdesc.colorAttachments[0].texture = color[i % color.count]
		rdesc.depthAttachment.texture = depth[i % color.count]
		let renc = cbuf.makeRenderCommandEncoder(descriptor: rdesc)!
		renc.setDepthStencilState(dss)
		renc.setCullMode(.front)
		renc.setDepthClipMode(.clamp)
		renc.setVertexBuffer(uni_vertices, offset: 0, index: 0)
		renc.setVertexBuffer(uni_uniforms, offset: 0, index: 1)
		renc.setFragmentBuffer(uni_uniforms, offset: 0, index: 0)
		renc.setFragmentSamplerState(samp, index: 0)
		renc.setFragmentSamplerState(samp, index: 1)
		renc.setRenderPipelineState(pipe)
		for (nidx, basevert, ioff, voff, foff, tex0, tex1) in draws {
			renc.setVertexBufferOffset(voff, index: 1)
			renc.setFragmentBufferOffset(foff, index: 0)
			renc.setFragmentTexture(textures[tex0], index: 0)
			renc.setFragmentTexture(textures[tex1], index: 1)
			renc.drawIndexedPrimitives(
				type: .triangleStrip,
				indexCount: nidx,
				indexType: .uint16,
				indexBuffer: uni_indices,
				indexBufferOffset: ioff,
				instanceCount: 1,
				baseVertex: basevert,
				baseInstance: 0
			)
		}

		renc.endEncoding()
		let buffer = lock.withLock { buffers.popLast() } ?? gpu.makeBuffer(length: imagebytes, options: .storageModeShared)!
		let download = cbuf.makeBlitCommandEncoder()!
		download.copy(
			from: color[i % color.count],
			sourceSlice: 0,
			sourceLevel: 0,
			sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
			sourceSize: size,
			to: buffer,
			destinationOffset: 0,
			destinationBytesPerRow: linebytes,
			destinationBytesPerImage: imagebytes
		)
		download.endEncoding()
		if i == 0 {
			cbuf.addCompletedHandler { _ in
				memcpy(outbuf, buffer.contents(), imagebytes)
			}
			cbuf.commit()
			cbuf.waitUntilCompleted()
		} else {
			sema.wait()
			cbuf.addCompletedHandler { _ in
				DispatchQueue.global().async {
					if (memcmp(outbuf, buffer.contents(), imagebytes) != 0) {
						fatalError("Two identical renders gave different results! (Took \(i) tries)");
					}
					lock.withLock { buffers.append(buffer) }
					sema.signal()
				}
			}
			cbuf.commit()
		}

//		MTLCaptureManager.shared().stopCapture()
	}}
}

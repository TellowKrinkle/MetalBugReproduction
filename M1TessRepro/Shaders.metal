#include <metal_stdlib>
using namespace metal;

struct Vertex {
	float4 pos [[attribute(0)]];
};

struct V2F {
	float4 pos [[position, invariant]];
	half4 color;
};

static float4 transformPos(float3 pos_, constant float4x4& uniform) {
	float4 pos = float4(pos_, 1.f);
	return float4(
		dot(uniform[0], pos),
		dot(uniform[1], pos),
		dot(uniform[2], pos),
		dot(uniform[3], pos));
}

[[patch(triangle, 3)]]
vertex V2F vs0(
	patch_control_point<Vertex> vertices [[stage_in]],
	uint patch [[patch_id]],
	float3 pos [[position_in_patch]],
	constant float4x4& transform [[buffer(1)]],
	constant uint& color [[buffer(2)]],
	constant ushort3& indices [[buffer(3)]])
{
	float4 r0 = pos.y * vertices[indices.y].pos;
	r0 = fma(vertices[indices.x].pos, pos.x, r0);
	r0 = fma(vertices[indices.z].pos, pos.z, r0);
	return { transformPos(r0.xyz, transform), unpack_unorm4x8_to_half(color) * r0.w };
}

vertex V2F vs1(
	uint vid [[vertex_id]],
	device const float4* vertices [[buffer(0)]],
	constant float4x4& transform [[buffer(1)]],
	constant uint& color [[buffer(2)]])
{
	float4 v = vertices[vid];
	return { transformPos(v.xyz, transform), unpack_unorm4x8_to_half(color) * v.w };
}

fragment half4 fs0(V2F in [[stage_in]]) {
	return in.color;
}

cbuffer Global : register(b0)
{
	float Time;
	float4x4 View;
	float4x4 Projection;
	float4 EyePosition;
}

cbuffer PerObject : register(b1)
{
	float4x4 World;
	float4x4 InvWorld;
	float4 AnimationCoords;
	float3 Blend;
	float Alpha;
}

cbuffer Uniforms : register(b2)
{

}

struct VOut
{
	float4 position : SV_POSITION;
	float4 colour : COLOUR;
	float2 texcoord : TEXCOORD0;
	float3 normal : TEXCOORD2;
	float3 tangent : TEXCOORD3;
	float3 bitangent : TEXCOORD4;
	float4 world_pos : TEXCOORD5;
};

VOut VS(float4 position : POSITION, float4 colour : COLOUR, float2 texcoord : TEXCOORD0, float3 normal : NORMAL, float3 tangent : TANGENT, float3 bitangent : BITANGENT)
{
	VOut output;
	float mx = 0.0f;
	float mz = 0.0f;

	mx += sin(position.z / 10 + Time) / 2;
	mx += sin(position.x / 4 + Time);
	mz += cos(position.z / 15 + position.x / 9 + Time) / 2;

	position.y += mx + mz;
	position.y += sin(Time) * 1.5;
	normal.x += mx / 10;
	normal.z += mz / 10;
	output.world_pos = position;
	output.position = mul(position, World);
	output.position = mul(position, View);
	output.position = mul(output.position, Projection);
	output.normal = mul(normal, (float3x3)InvWorld);
	output.texcoord = texcoord;
	output.colour = colour;
	output.normal = normalize(mul(normal, (float3x3)InvWorld));
	output.tangent = normalize(mul(tangent, (float3x3)InvWorld));
	output.bitangent = normalize(mul(bitangent, (float3x3)InvWorld));
	return output;
}

Texture2D TexDiffuse : register(t1);
Texture2D TexNormal : register(t2);
Texture2D TexSpecular : register(t3);
Texture2D TexLight : register(t4);
Texture2D TexDepth : register(t5);
SamplerState Sampler;

float4 Specular(float3 v, float3 l, float3 n, float i, float p)
{
	float3 r = normalize(reflect(normalize(l), normalize(n)));
    float d = saturate(dot(r, v));

    return i * pow(d, p) * float4(1.0f, 1.0f, 1.0f, 1.0f);
}

float4 PS(VOut input) : SV_TARGET
{
	float x = (input.texcoord.x * AnimationCoords.z) + AnimationCoords.x;
	float y = (input.texcoord.y * AnimationCoords.w) + AnimationCoords.y;
	float2 coords = float2(x, y);
	coords *= 16;
	coords += Time / 15;
	float4 diffuse = TexDiffuse.Sample(Sampler, coords);

	float4 normal = normalize(TexNormal.Sample(Sampler, coords) * 2.0f - 1.0f);
	normal = float4((normal.x * input.tangent) + (normal.y * input.bitangent) + (normal.z * input.normal), 1.0f);

	diffuse.rgb *= input.colour.rgb * Blend;
	diffuse.a *= Alpha;

	float3 lightDir = float3(0, -1, -1);

	float4 view = normalize(EyePosition - input.world_pos);
	float4 specular = Specular(view.xyz, lightDir, normal.rgb, TexSpecular.Sample(Sampler, coords).r, 1);
	float depth = TexDepth.Sample(Sampler, coords).r;

	diffuse.rgb *= saturate(dot(-lightDir, normal.rgb));
	diffuse.rgb += specular.rgb;
	diffuse.rgb = saturate(diffuse.rgb);
	return float4(diffuse.rgb, 0.9);
}
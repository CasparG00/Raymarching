// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Infinite Plane
// n.xyz: normal of the plane (normalized)
// n.w: offset
float sdPlane(float3 p, float4 n)
{
	return dot(p, n.xyz) + n.w;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Infinite Cylinder
float sdCylinder(float3 p, float3 c)
{
	return length(p.xz - c.xy) - c.z;
}

// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

// Mod Position Axis
float opMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p + halfsize) / size);
	p = fmod(p + halfsize,size) - halfsize;
	p = fmod(-p + halfsize,size) - halfsize;
	return c;
}

float opWave(inout float p, float amplitude, float frequency)
{
	p += sin(p * frequency) * amplitude;
	return p;
}

float opTwist(inout float3 p, float k)
{
	float c = cos(k * p.y);
	float s = sin(k * p.y);
	float2x2 m = float2x2(c, -s, s, c);
	p = float3(mul(m, p.xz), p.y);
	
	return p;
}

float2x2 opRot(float a)
{
	float s = sin(a);
	float c = cos(a);

	return float2x2(c, -s, s, c);
}


// SMOOTH BOOLEAN OPERATORS

float4 opUS( float4 d1, float4 d2, float k ) 
{
	float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
	float3 color = lerp(d2.rgb, d1.rgb, h);
	float dist = lerp( d2.w, d1.w, h ) - k*h*(1.0-h); 
	return float4(color,dist);
}

float opSS( float d1, float d2, float k ) 
{
	float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
	return lerp( d2, -d1, h ) + k*h*(1.0-h); 
}

float opIS( float d1, float d2, float k ) 
{
	float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
	return lerp( d2, d1, h ) + k*h*(1.0-h); 
}
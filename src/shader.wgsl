// Uniforms passed from the CPU each frame
struct Uniforms {
    time:       f32,
    resolution: vec2<f32>,
    depth:      u32,
};

@group(0) @binding(0)
var<uniform> u: Uniforms;

// -------------------------------------------------------
// Sierpiński triangle membership test (pure recursion)
// Uses Sierpiński's rule: a point is OUTSIDE if, at any
// level, it lands in the middle triangle.
// -------------------------------------------------------
fn in_sierpinski(p_in: vec2<f32>, depth: u32) -> bool {
    var p = p_in;
    for (var i: u32 = 0u; i < depth; i++) {
        // Scale into [0,1] triangle coordinates via barycentric trick
        p = p * 2.0;
        // If the point sits in the central "hole", it is not in the set
        if (p.x > 1.0 && p.y < 1.0 - (p.x - 1.0)) {
            return false;
        }
        // Fold back into the lower-left triangle for the next level
        if p.x > 1.0 { p.x = p.x - 1.0; }
        if p.y > 1.0 { p.y = p.y - 1.0; }
        p = fract(p);
    }
    return true;
}

@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> @builtin(position) vec4<f32> {
    // Full-screen triangle (no vertex buffer needed)
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0),
    );
    return vec4<f32>(pos[vi], 0.0, 1.0);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    // Normalise pixel → [0,1] square, keep aspect ratio
    let aspect = u.resolution.x / u.resolution.y;
    var uv = frag_coord.xy / u.resolution;
    uv.x *= aspect;

    // Slowly pan + zoom over time so the fractal feels alive
    let zoom  = 1.0 + 0.3 * sin(u.time * 0.4);
    let pan   = vec2<f32>(
        0.5 * aspect + 0.15 * sin(u.time * 0.25),
        0.5           + 0.15 * cos(u.time * 0.2),
    );
    uv = (uv - pan) * zoom + vec2<f32>(0.5 * aspect, 0.5);

    // Clamp to valid Sierpiński domain [0,1]²
    if uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 {
        return vec4<f32>(0.04, 0.04, 0.08, 1.0);
    }

    let inside = in_sierpinski(uv, u.depth);

    // Colour: vivid cyan/purple palette shifting with time
    let hue_shift = u.time * 0.08;
    let col = select(
        // Background — deep dark blue
        vec3<f32>(0.04, 0.04, 0.10),
        // Fractal — animated hue through RGB rotation
        vec3<f32>(
            0.5 + 0.5 * cos(hue_shift + 0.0),
            0.5 + 0.5 * cos(hue_shift + 2.094),
            0.5 + 0.5 * cos(hue_shift + 4.189),
        ),
        inside,
    );

    return vec4<f32>(col, 1.0);
}
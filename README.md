# wgpu_recursion

Generative art using **Rust + wgpu + WGSL shaders**. Recursion lives entirely on
the GPU — no CPU geometry needed.

## What it renders

A **Sierpiński triangle** computed per-pixel in a WGSL fragment shader. Each
pixel tests whether its coordinate is "inside" the fractal by recursively
halving the coordinate space `depth` times. The depth cycles 1 → 8 every 3
seconds so you watch the fractal converge live. A slow pan/zoom animation keeps
it visually alive.

## Run

```bash
cargo run --release
```

## Key concepts

| Concept                       | Where                            |
| ----------------------------- | -------------------------------- |
| Full-screen triangle trick    | `vs_main` in shader.wgsl         |
| Sierpiński recursion loop     | `in_sierpinski()` in shader.wgsl |
| Uniform data (time, depth)    | `Uniforms` struct in main.rs     |
| wgpu surface + pipeline setup | `run()` in main.rs               |

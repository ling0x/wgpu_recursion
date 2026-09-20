use std::sync::Arc;
use std::time::Instant;
use winit::{
    application::ApplicationHandler,
    dpi::LogicalSize,
    event::WindowEvent,
    event_loop::{ActiveEventLoop, ControlFlow},
    window::Window,
};

use crate::gpu::{init_wgpu, RenderState, Uniforms};

pub struct App {
    render_state: Option<RenderState>,
    start: Instant,
}

impl App {
    pub fn new() -> Self {
        Self {
            render_state: None,
            start: Instant::now(),
        }
    }
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.render_state.is_some() {
            return;
        }

        let window = Arc::new(
            event_loop
                .create_window(
                    Window::default_attributes()
                        .with_title("Sierpiński — wgpu recursive shader")
                        .with_inner_size(LogicalSize::new(900u32, 900u32)),
                )
                .unwrap(),
        );

        self.render_state = Some(pollster::block_on(init_wgpu(window)));
        self.start = Instant::now();
    }

    fn window_event(
        &mut self,
        event_loop: &ActiveEventLoop,
        _window_id: winit::window::WindowId,
        event: WindowEvent,
    ) {
        let Some(state) = self.render_state.as_mut() else {
            return;
        };

        match event {
            WindowEvent::CloseRequested => event_loop.exit(),
            WindowEvent::Resized(new_size) => state.resize(new_size),
            _ => {}
        }
    }

    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        event_loop.set_control_flow(ControlFlow::Poll);

        let Some(state) = self.render_state.as_mut() else {
            return;
        };

        // Depth cycles 1 -> 8 every 3 seconds so the fractal converges on screen.
        let elapsed = self.start.elapsed().as_secs_f32();
        let depth = ((elapsed / 3.0) as u32 % 8) + 1;

        let uniforms = Uniforms::new(elapsed, state.resolution(), depth);
        state.render(&uniforms);
    }
}

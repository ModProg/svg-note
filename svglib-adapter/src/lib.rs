#![feature(drain_filter)]
use std::mem::replace;
use std::str::FromStr;

use gdnative::api::line_2d::{LineCapMode, LineJointMode};
use gdnative::api::Line2D;
use gdnative::prelude::*;
use svg_notes::elements::{Element, Line, Point};
use svg_notes::{colors, Document};

enum Shape2D {
    Line(Line, Ref<Line2D, Shared>),
}

impl Shape2D {
    fn add_to(&self, node: TRef<Node2D>) {
        match self {
            Shape2D::Line(_, child) => node.add_child(child, false),
        }
    }

    fn generate(&self) {
        match self {
            Shape2D::Line(line, node) => {
                let node = unsafe { node.assume_safe() };
                line.points
                    .iter()
                    .skip(node.points().len() as usize)
                    .for_each(|&Point(x, y, _)| node.add_point(Vector2::new(x, y), -1))
            }
        }
    }
}

fn color_g2s(color: colors::Color) -> core_types::Color {
    let color = color.floats();
    core_types::Color::rgba(color.0, color.1, color.2, color.3)
}

impl From<Element> for Shape2D {
    fn from(e: Element) -> Self {
        match e {
            Element::Line(line, _) => {
                let line2d = Line2D::new();
                line2d.set_width(line.width.into());
                line2d.set_antialiased(true);
                line2d.set_end_cap_mode(LineCapMode::ROUND.into());
                line2d.set_begin_cap_mode(LineCapMode::ROUND.into());
                line2d.set_joint_mode(LineJointMode::ROUND.into());
                line2d.set_default_color(color_g2s(line.color));
                Shape2D::Line(line, line2d.into_shared())
            }
            Element::Ngon(_, _) => todo!(),
            Element::Ellipse(_, _) => todo!(),
        }
    }
}

#[derive(NativeClass)]
#[inherit(Reference)]
struct Project {
    #[property]
    filepath: String,
    #[property]
    dirty: bool,
    current_line: Option<Line>,
    shapes: Vec<Shape2D>,
}

#[gdnative::methods]
impl Project {
    fn new(_owner: &Reference) -> Self {
        Self {
            filepath: String::new(),
            dirty: false,
            current_line: None,
            shapes: vec![],
        }
    }

    #[export]
    fn empty(&mut self, _owner: &Reference) {}

    #[export]
    fn draw(&self, _owner: &Reference, canvas: Ref<Node2D>) {
        let canvas = unsafe { canvas.assume_safe() };
        self.shapes.iter().for_each(|s| s.add_to(canvas));
    }

    #[export]
    fn load(&mut self, _owner: &Reference, string: String) -> bool {
        if self.shapes.len() > 0 {
            false
        } else {
            if let Some(Document { elements }) = Document::from_str(&string).ok() {
                self.shapes = elements.into_iter().map(Shape2D::from).collect();
                self.shapes.iter().for_each(|s| {
                    s.generate();
                });
                true
            } else {
                false
            }
        }
    }

    #[export]
    fn _to_string(&self, _owner: &Reference) -> String {
        todo!()
        // self.document
        //     .as_ref()
        //     .map(Document::to_string)
        //     .unwrap_or("".to_string())
    }

    #[export]
    fn new_line(&mut self, _owner: &Reference, color: core_types::Color, width: f32) -> bool {
        todo!()
        // if self.document.is_some() {
        //     self.end_line(_owner);
        //     self.current_line = Some(Line {
        //         color: colors::Color::rgbaf(color.r, color.g, color.b, color.a),
        //         width,
        //         points: vec![],
        //     });
        //     true
        // } else {
        //     false
        // }
    }

    #[export]
    fn has_line(&self, _owner: &Reference) -> bool {
        self.current_line.is_some()
    }

    #[export]
    fn end_line(&mut self, _owner: &Reference) -> bool {
        todo!()
        // if let Some(document) = &mut self.document {
        //     if self.current_line.is_some() {
        //         let line = replace(&mut self.current_line, None).unwrap();
        //         document.elements.push(Element::Line(line, {
        //             self.current_id += 1;
        //             self.current_id
        //         }));
        //         true
        //     } else {
        //         false
        //     }
        // } else {
        //     false
        // }
    }

    #[export]
    fn draw_to(&mut self, _owner: &Reference, position: Vector2, width: f32) -> bool {
        if let Some(current_line) = &mut self.current_line {
            current_line
                .points
                .push(Point(position.x, position.y, width));
            true
        } else {
            false
        }
    }

    #[export]
    fn erase_line(&mut self, _owner: &Reference, position: Vector2, width: f32) -> Vec<i32> {
        todo!()
        // if let Some(document) = &mut self.document {
        //     document
        //         .elements
        //         .drain_filter(|e| {
        //             if let Element::Line(Line { points, .. }, _) = e {
        //                 points.iter().any(|p| {
        //                     position.distance_to(Vector2 {
        //                         x: p.0,
        //                         y: p.1,
        //                         _unit: position._unit,
        //                     }) < p.2 + width
        //                 })
        //             } else {
        //                 false
        //             }
        //         })
        //         .map(|v| match v {
        //             Element::Line(_, i) => i,
        //             Element::Ngon(_, i) => i,
        //             Element::Ellipse(_, i) => i,
        //         })
        //         .collect()
        // } else {
        //     vec![]
        // }
    }
}

fn init(handle: InitHandle) {
    handle.add_class::<Project>();
    init_panic_hook();
}

godot_init!(init);

pub fn init_panic_hook() {
    // To enable backtrace, you will need the `backtrace` crate to be included in your cargo.toml, or
    // a version of rust where backtrace is included in the standard library (e.g. Rust nightly as of the date of publishing)
    // use backtrace::Backtrace;
    // use std::backtrace::Backtrace;
    let old_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        let loc_string;
        if let Some(location) = panic_info.location() {
            loc_string = format!("file '{}' at line {}", location.file(), location.line());
        } else {
            loc_string = "unknown location".to_owned()
        }

        let error_message;
        if let Some(s) = panic_info.payload().downcast_ref::<&str>() {
            error_message = format!("[RUST] {}: panic occurred: {:?}", loc_string, s);
        } else if let Some(s) = panic_info.payload().downcast_ref::<String>() {
            error_message = format!("[RUST] {}: panic occurred: {:?}", loc_string, s);
        } else {
            error_message = format!("[RUST] {}: unknown panic occurred", loc_string);
        }
        godot_error!("{}", error_message);
        // Uncomment the following line if backtrace crate is included as a dependency
        // godot_error!("Backtrace:\n{:?}", Backtrace::new());
        (*(old_hook.as_ref()))(panic_info);

        unsafe {
            if let Some(gd_panic_hook) =
                gdnative::api::utils::autoload::<gdnative::api::Node>("rust_panic_hook")
            {
                gd_panic_hook.call(
                    "rust_panic_hook",
                    &[GodotString::from_str(error_message).to_variant()],
                );
            }
        }
    }));
}

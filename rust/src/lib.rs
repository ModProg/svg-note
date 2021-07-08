#![feature(drain_filter)]
use std::str::FromStr;

use gdnative::api::line_2d::{LineCapMode, LineJointMode};
use gdnative::api::Line2D;
use gdnative::prelude::*;
use svg_notes::elements::{Element, Line, Point};
use svg_notes::{colors, Document};

enum Shape2D {
    Line(Line, Ref<Line2D, Shared>),
}

const MINDIST_INLINE: f32 = 2.0;
const MINDIST_NEW_POINT: f32 = 0.2;

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
                node.clear_points();
                line.points
                    .iter()
                    // .iter().zip(node.points().read().iter())
                    // .skip(node.points().len() as usize)
                    .for_each(|&Point(x, y, _)| node.add_point(Vector2::new(x, y), -1))
            }
        }
    }

    fn draw_to(&mut self, position: Vector2, width: f32) {
        match self {
            Shape2D::Line(line, _) => {
                let new = Point(position.x, position.y, width);
                if line.points.len() > 1
                    && line.points[line.points.len() - 2]
                        .distance_to(line.points[line.points.len() - 1])
                        < MINDIST_INLINE
                {
                    let l = line.points.len();
                    line.points[l - 1] = new;
                } else if line.points.len() == 0
                    || line.points[line.points.len() - 1].distance_to(new) > MINDIST_NEW_POINT
                {
                    line.points.push(new);
                } else {
                }
            }
        }
        self.generate()
    }

    fn svg_elem(&self) -> Element {
        match self {
            Shape2D::Line(line, _) => Element::Line(line.clone(), 0),
        }
    }

    fn is_at(&self, position: Vector2, width: f32) -> bool {
        match self {
            Shape2D::Line(Line { points, .. }, _) => points.iter().any(|p| {
                position.distance_to(Vector2 {
                    x: p.0,
                    y: p.1,
                    _unit: position._unit,
                }) < p.2 + width
            }),
        }
    }

    fn erase(&self) {
        match self {
            Shape2D::Line(_, line2d) => unsafe { line2d.assume_safe() }.hide(),
        }
    }

    fn erased(&self) -> bool {
        match self {
            Shape2D::Line(_, line2d) => !unsafe { line2d.assume_safe() }.is_visible(),
        }
    }
}

fn color_g2s(color: core_types::Color) -> colors::Color {
    colors::Color::rgbaf(color.r, color.g, color.b, color.a)
}
fn color_s2g(color: colors::Color) -> core_types::Color {
    let color = color.floats();
    core_types::Color::rgba(color.0, color.1, color.2, color.3)
}

impl From<Line> for Shape2D {
    fn from(line: Line) -> Self {
        let line2d = Line2D::new();
        line2d.set_width(line.width.into());
        line2d.set_antialiased(true);
        line2d.set_end_cap_mode(LineCapMode::ROUND.into());
        line2d.set_begin_cap_mode(LineCapMode::ROUND.into());
        line2d.set_joint_mode(LineJointMode::ROUND.into());
        line2d.set_default_color(color_s2g(line.color));
        Shape2D::Line(line, line2d.into_shared())
    }
}

impl From<Element> for Shape2D {
    fn from(e: Element) -> Self {
        match e {
            Element::Line(line, _) => line.into(),
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
    shapes: Vec<Shape2D>,
    canvas: Option<Ref<Node2D>>,
}

#[gdnative::methods]
impl Project {
    fn new(_owner: &Reference) -> Self {
        Self {
            filepath: String::new(),
            dirty: false,
            shapes: vec![],
            canvas: None,
        }
    }

    #[export]
    fn empty(&mut self, _owner: &Reference) {}

    #[export]
    fn draw(&mut self, _owner: &Reference, canvas: Ref<Node2D>) {
        self.canvas = Some(canvas);
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
        Document {
            elements: self
                .shapes
                .iter()
                .filter_map(|v| if v.erased() { None } else { Some(v.svg_elem()) })
                .collect(),
        }
        .to_string()
    }

    #[export]
    fn new_line(&mut self, _owner: &Reference, color: core_types::Color, width: f32) -> bool {
        let line: Shape2D = Line {
            color: color_g2s(color),
            width,
            points: vec![],
        }
        .into();
        if let Some(canvas) = self.canvas {
            let canvas = unsafe { canvas.assume_safe() };
            line.add_to(canvas)
        }
        self.shapes.push(line);
        true
    }

    #[export]
    fn draw_to(&mut self, _owner: &Reference, position: Vector2, width: f32) -> bool {
        if let Some(shape) = self.shapes.last_mut() {
            shape.draw_to(position, width);
            true
        } else {
            false
        }
    }

    #[export]
    fn erase_line(&mut self, _owner: &Reference, position: Vector2, width: f32) {
        self.shapes
            .drain_filter(|e| e.is_at(position, width))
            .for_each(|e| e.erase());
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

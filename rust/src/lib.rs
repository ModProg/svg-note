#![feature(drain_filter, duration_consts_2, backtrace)]
use std::{
    str::FromStr,
    time::{Duration, Instant},
};

use gdnative::{
    api::{
        line_2d::{LineCapMode, LineJointMode},
        Geometry, Line2D, Polygon2D,
    },
    prelude::*,
};
use itertools::{
    FoldWhile::{Continue, Done},
    Itertools,
};
use svg_notes::{
    colors,
    elements::{Element, Line, LinePoint, Polyline, PolylinePoint},
    Document,
};

enum Shape2D {
    Line(Line, Ref<Line2D, Shared>),
    Polyline {
        polyline: Polyline,
        stroke: Ref<Line2D, Shared>,
        fill: Option<Ref<Polygon2D, Shared>>,
        last_movement: Instant,
    },
}

const MINDIST_INLINE: f32 = 2.0;
const MINDIST_NEW_POINT: f32 = 0.2;
const MAXDIST_NEW_SEG: f32 = 1.0;
const DELAY_NEW_SEG: Duration = Duration::from_secs_f32(0.3);

impl Shape2D {
    fn add_to(&self, node: TRef<Node2D>) {
        match self {
            Shape2D::Line(_, child) => node.add_child(child, false),
            Shape2D::Polyline { stroke, fill, .. } => {
                node.add_child(stroke, false);
                if let Some(fill) = fill {
                    node.add_child(fill, false);
                }
            }
        }
    }

    fn generate(&mut self) {
        match self {
            Shape2D::Line(line, node) => {
                let node = unsafe { node.assume_safe() };
                node.clear_points();
                line.points
                    .iter()
                    .for_each(|&LinePoint(x, y, _)| node.add_point(Vector2::new(x, y), -1))
            }
            Shape2D::Polyline {
                polyline,
                stroke,
                fill,
                ..
            } => {
                let node = unsafe { stroke.assume_safe() };
                node.clear_points();
                if polyline.fill.a > 0 {
                    let fill = unsafe { fill.unwrap().assume_safe() };
                    let line: Vec<PolylinePoint> = polyline
                        .points
                        .iter()
                        .fold_while(Vec::<PolylinePoint>::new(), |mut line, segment| {
                            let mut intersection = None;
                            for i in 1..line.len().max(1) - 1 {
                                intersection = {
                                    let intersection = Geometry::godot_singleton()
                                        .segment_intersects_segment_2d(
                                            Vector2::new(line[i - 1].0, line[i - 1].1),
                                            Vector2::new(line[i].0, line[i].1),
                                            Vector2::new(
                                                line[line.len() - 1].0,
                                                line[line.len() - 1].1,
                                            ),
                                            Vector2::new(segment.0, segment.1),
                                        );
                                    if intersection.is_nil() {
                                        None
                                    } else {
                                        let vec = intersection.to_vector2();
                                        Some((vec, i))
                                    }
                                };
                                if intersection.is_some() {
                                    break;
                                }
                            }
                            if let Some((intersection, i)) = intersection {
                                line.drain(0..i);
                                line.insert(0, PolylinePoint(intersection.x, intersection.y));
                                line.push(PolylinePoint(intersection.x, intersection.y));
                                Done(line)
                            } else {
                                line.push(*segment);
                                Continue(line)
                            }
                        })
                        .into_inner();
                    fill.set_polygon(
                        line.iter()
                            .map(|&PolylinePoint(x, y)| Vector2::new(x, y))
                            .collect(),
                    );
                }

                polyline
                    .points
                    .iter()
                    .for_each(|&PolylinePoint(x, y)| node.add_point(Vector2::new(x, y), -1))
            }
        }
    }

    fn draw_to(&mut self, position: Vector2, width: f32) -> bool {
        let mut blink = false;
        match self {
            Shape2D::Line(line, _) => {
                let new = LinePoint(position.x, position.y, width);
                if line.points.len() > 1
                    && line.points[line.points.len() - 2]
                        .distance_to(line.points[line.points.len() - 1])
                        < MINDIST_INLINE
                {
                    let l = line.points.len();
                    line.points[l - 1] = new;
                } else if line.points.is_empty()
                    || line.points[line.points.len() - 1].distance_to(new) > MINDIST_NEW_POINT
                {
                    line.points.push(new);
                } else {
                }
            }
            Shape2D::Polyline {
                polyline,
                last_movement,
                ..
            } => {
                let new = PolylinePoint(position.x, position.y);
                if polyline.points.len() > 1 {
                    let l = polyline.points.len();
                    let moved = polyline.points[l - 1].distance_to(new) > MAXDIST_NEW_SEG;
                    if !moved
                        && polyline.points[l - 1].distance_to(polyline.points[l - 2])
                            > MINDIST_INLINE
                        && Instant::now().elapsed() > DELAY_NEW_SEG
                    {
                        polyline.points.push(new);
                        *last_movement = Instant::now()
                    } else {
                        polyline.points[l - 1] = new;

                        if moved {
                            *last_movement = Instant::now()
                        }
                    }
                } else {
                    polyline.points.push(new);
                    blink = true;
                }
            }
        }
        self.generate();
        blink
    }

    fn svg_elem(&self) -> Element {
        match self {
            Shape2D::Line(line, _) => Element::Line(line.clone()),
            Shape2D::Polyline { polyline, .. } => Element::Polyline(polyline.clone()),
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
            Shape2D::Polyline { .. } => todo!(),
        }
    }

    fn erase(&self) {
        match self {
            Shape2D::Line(_, line2d) => unsafe { line2d.assume_safe() }.hide(),
            Shape2D::Polyline { stroke, .. } => {
                unsafe { stroke.assume_safe() }.hide();
            }
        }
    }

    fn erased(&self) -> bool {
        match self {
            Shape2D::Line(_, line2d) => !unsafe { line2d.assume_safe() }.is_visible(),
            Shape2D::Polyline { stroke, .. } => !unsafe { stroke.assume_safe() }.is_visible(),
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
impl From<Polyline> for Shape2D {
    fn from(polyline: Polyline) -> Self {
        let stroke = Line2D::new();
        stroke.set_width(polyline.width.into());
        stroke.set_antialiased(true);
        stroke.set_end_cap_mode(LineCapMode::ROUND.into());
        stroke.set_begin_cap_mode(LineCapMode::ROUND.into());
        stroke.set_joint_mode(LineJointMode::ROUND.into());
        stroke.set_default_color(color_s2g(polyline.stroke));
        let fill = if polyline.fill.a > 0 {
            let fill = Polygon2D::new();
            fill.set_antialiased(true);
            fill.set_color(color_s2g(polyline.fill));
            Some(fill.into_shared())
        } else {
            None
        };
        Shape2D::Polyline {
            polyline,
            stroke: stroke.into_shared(),
            fill,
            last_movement: Instant::now(),
        }
    }
}

impl From<Element> for Shape2D {
    fn from(e: Element) -> Self {
        match e {
            Element::Line(line) => line.into(),
            Element::Ngon(_) => todo!(),
            Element::Ellipse(_) => todo!(),
            Element::Polyline(polyline) => polyline.into(),
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
        if !self.shapes.is_empty() {
            false
        } else if let Ok(Document { elements }) = Document::from_str(&string) {
            self.shapes = elements.into_iter().map(Shape2D::from).collect();
            self.shapes.iter_mut().for_each(|s| {
                s.generate();
            });
            true
        } else {
            false
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
    fn new_polyline(&mut self, _owner: &Reference, color: core_types::Color, width: f32) -> bool {
        let line: Shape2D = Polyline {
            stroke: color_g2s(color),
            fill: color_g2s(color).with_opacity(color.a / 2.),
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
    use std::backtrace::Backtrace;
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
        godot_error!("Backtrace:\n{:?}", Backtrace::capture());
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

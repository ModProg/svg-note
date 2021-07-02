use gdnative::prelude::*;
use svg_notes::elements::{Element, Line, Point};
use svg_notes::{colors, Document};

#[derive(NativeClass)]
#[inherit(Node)]
struct GodotDocument;

impl GodotDocument {
    fn new(_owner: &Node) -> Self {
        Self
    }
}

#[derive(NativeClass)]
#[inherit(Node)]
struct SvgLib;

#[gdnative::methods]
impl SvgLib {
    fn new(_owner: &Node) -> Self {
        SvgLib
    }

    #[export]
    fn serialize_document(&self, _owner: &Node, strokes: Vec<Ref<Node2D>>) -> String {
        let elements: Vec<Element> = strokes
            .iter()
            .map(|v| {
                let e = Element::Line({
                    let v: TRef<Node2D> = unsafe { v.assume_safe() };
                    let e = Line {
                        color: {
                            let c: core_types::Color =
                                Color::from_variant(&v.get("color")).unwrap();
                            colors::Color::rgbaf(c.r, c.g, c.b, c.a)
                        },
                        width: 4.,
                        points: {
                            let p = core_types::VariantArray::from_variant(&v.get("points"))
                                .map(|v| core_types::Vector2Array::from_variant_array(&v))
                                .map_err(|e| {
                                    godot_dbg!(e);
                                })
                                .unwrap();
                            let p = p.read();
                            p.iter().map(|p| Point(p.x, p.y, 4.)).collect()
                        },
                    };
                    e
                });
                e
            })
            .collect();
        Document { elements }.to_string()
    }
}

fn init(handle: InitHandle) {
    handle.add_class::<SvgLib>();
}

godot_init!(init);

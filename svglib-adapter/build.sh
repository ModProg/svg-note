#!/bin/bash
cargo build 
cp target/debug/libsvglib_adapter.so ../godot/Lib/svg/libsvg.so

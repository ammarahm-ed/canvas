#![allow(non_snake_case)]

extern crate core;

use std::any::Any;
use std::borrow::Cow;
use std::collections::HashMap;
use std::error::Error;
use std::ffi::{CStr, CString};
use std::io::Read;
use std::os::raw::{c_char, c_int, c_longlong, c_uint, c_ulong, c_void};
use std::os::unix::io::FromRawFd;
use std::os::unix::prelude::IntoRawFd;
use std::pin::Pin;
use std::sync::atomic::{AtomicBool, AtomicIsize, Ordering};
use std::sync::Arc;

use ::jni::signature::JavaType;
use ::jni::sys::jint;
use ::jni::JavaVM;
use cxx::{let_cxx_string, type_id, CxxString, CxxVector, ExternType, SharedPtr, UniquePtr};
use once_cell::sync::OnceCell;
use parking_lot::lock_api::{RwLock, RwLockReadGuard, RwLockWriteGuard};
use parking_lot::{Mutex, MutexGuard, RawMutex, RawRwLock};

use canvas_2d::context::compositing::composite_operation_type::CompositeOperationType;
use canvas_2d::context::drawing_paths::fill_rule::FillRule;
use canvas_2d::context::fill_and_stroke_styles::paint::paint_style_set_color_with_string;
use canvas_2d::context::line_styles::line_cap::LineCap;
use canvas_2d::context::line_styles::line_join::LineJoin;
use canvas_2d::context::text_styles::text_align::TextAlign;
use canvas_2d::context::text_styles::text_direction::TextDirection;
use canvas_2d::context::{Context, ContextWrapper};
use canvas_2d::utils::color::{parse_color, to_parsed_color};
use canvas_2d::utils::image::{
    from_bitmap_slice, from_image_slice, from_image_slice_encoded,
    from_image_slice_encoded_no_copy, from_image_slice_no_copy, to_image, to_image_encoded,
    to_image_encoded_from_data,
};

use crate::utils::gl::st::{SurfaceTexture, SURFACE_TEXTURE};

pub mod choregrapher;
mod jni_compat;
pub mod raf;
pub mod utils;

pub static JVM: OnceCell<JavaVM> = OnceCell::new();

pub static API_LEVEL: OnceCell<i32> = OnceCell::new();

pub(crate) const BUILD_VERSION_CLASS: &str = "android/os/Build$VERSION";

#[no_mangle]
pub extern "system" fn JNI_OnLoad(vm: JavaVM, _reserved: *const c_void) -> jint {
    if let Ok(mut env) = vm.get_env() {
        API_LEVEL.get_or_init(|| {
            let clazz = env.find_class(BUILD_VERSION_CLASS).unwrap();

            let sdk_int_id = env.get_static_field_id(&clazz, "SDK_INT", "I").unwrap();

            let sdk_int = env.get_static_field_unchecked(
                clazz,
                sdk_int_id,
                JavaType::Primitive(jni::signature::Primitive::Int),
            );

            sdk_int.unwrap().i().unwrap()
        });

        SURFACE_TEXTURE.get_or_init(|| SurfaceTexture::new());
    }

    JVM.get_or_init(|| vm);
    jni::sys::JNI_VERSION_1_6
}

pub struct BitmapBytes(utils::image::BitmapBytes);

#[cxx::bridge]
pub(crate) mod ffi {
    unsafe extern "C++" {
        include!("canvas-cxx/src/canvas2d.rs.h");
        pub(crate) type CanvasRenderingContext2D = canvas_cxx::canvas2d::CanvasRenderingContext2D;
        pub(crate) type PaintStyle = canvas_cxx::canvas2d::PaintStyle;
        pub(crate) fn canvas_native_paint_style_from_bytes(
            context: &CanvasRenderingContext2D,
            repetition: i32,
            width: i32,
            height: i32,
            bytes: &[u8],
        ) -> Box<PaintStyle>;
        pub(crate) fn canvas_native_paint_style_empty() -> Box<PaintStyle>;
    }

    extern "Rust" {
        type BitmapBytes;
        fn canvas_native_context_create_pattern_bytes(
            context: &mut CanvasRenderingContext2D,
            bytes: i64,
            repetition: &str,
        ) -> Box<PaintStyle>;
    }
}

fn canvas_native_context_create_pattern_bytes(
    context: &mut ffi::CanvasRenderingContext2D,
    bm: i64,
    repetition: &str,
) -> Box<ffi::PaintStyle> {
    unsafe {
        canvas_2d::context::fill_and_stroke_styles::pattern::Repetition::try_from(repetition)
            .map_or(ffi::canvas_native_paint_style_empty(), |repetition| {
                if bm == 0 {
                    return ffi::canvas_native_paint_style_empty();
                }
                let bm = unsafe { bm as *mut BitmapBytes };
                let mut bm = unsafe { *Box::from_raw(bm) };
                let mut width = 0;
                let mut height = 0;
                {
                    if let Some(info) = bm.0.info() {
                        width = info.width();
                        height = info.height();
                    }
                }
                if let Some(bytes) = bm.0.data_mut() {
                    return ffi::canvas_native_paint_style_from_bytes(
                        context,
                        repetition.into(),
                        width as i32,
                        height as i32,
                        bytes,
                    );
                }
                ffi::canvas_native_paint_style_empty()
            })
    }
}

/* Utils */

#[derive(Clone, Copy)]
#[repr(isize)]
pub enum LogPriority {
    UNKNOWN = 0,
    DEFAULT = 1,
    VERBOSE = 2,
    DEBUG = 3,
    INFO = 4,
    WARN = 5,
    ERROR = 6,
    FATAL = 7,
    SILENT = 8,
}

impl TryFrom<isize> for LogPriority {
    type Error = &'static str;

    fn try_from(value: isize) -> Result<Self, Self::Error> {
        if value < 0 || value > 8 {
            Err("Invalid LogPriority")
        } else {
            match value {
                0 => Ok(LogPriority::UNKNOWN),
                1 => Ok(LogPriority::DEFAULT),
                2 => Ok(LogPriority::VERBOSE),
                3 => Ok(LogPriority::DEBUG),
                4 => Ok(LogPriority::INFO),
                5 => Ok(LogPriority::WARN),
                6 => Ok(LogPriority::ERROR),
                7 => Ok(LogPriority::FATAL),
                8 => Ok(LogPriority::SILENT),
                _ => Err("Invalid LogPriority"),
            }
        }
    }
}

extern "C" {
    pub fn __android_log_write(prio: c_int, tag: *const c_char, text: *const c_char) -> c_int;
}

pub fn _log(priority: isize, tag: &str, text: &str) {
    __log(priority.try_into().unwrap(), tag, text);
}

pub fn __log(priority: LogPriority, tag: &str, text: &str) {
    let tag = CString::new(tag).unwrap();
    let text = CString::new(text).unwrap();
    unsafe {
        __android_log_write(priority as c_int, tag.as_ptr(), text.as_ptr());
    }
}

pub fn console_log(text: &CxxString) {
    let text = text.to_string_lossy();
    __log(LogPriority::INFO, "JS", text.as_ref());
}

pub fn console_log_rust(text: &str) {
    __log(LogPriority::INFO, "JS", text);
}

pub fn to_rust_string(value: &[c_char]) -> String {
    if value.is_empty() {
        return String::new();
    }
    unsafe { CStr::from_ptr(value.as_ptr()).to_string_lossy().to_string() }
}

pub fn write_to_string(value: &[c_char], mut buf: Pin<&mut CxxString>) {
    if value.is_empty() {
        buf.as_mut().push_str("");
        return;
    }
    let string = unsafe { CStr::from_ptr(value.as_ptr()).to_string_lossy() };
    buf.push_str(string.as_ref());
}

pub fn str_to_buf(value: &str) -> Vec<u8> {
    value.as_bytes().to_vec()
}

pub fn string_to_buf(value: String) -> Vec<u8> {
    value.into_bytes()
}
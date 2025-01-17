#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]

use jni::JNIEnv;
use jni::objects::{JClass, JString, JByteBuffer, JObject};
use jni::sys::{jboolean, jbyteArray, jint, jlong, JNI_FALSE, JNI_TRUE, jstring};

use crate::common::context::image_asset::{ImageAsset, OutputFormat};

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeInit(
    _: JNIEnv,
    _: JClass,
) -> jlong {
    Box::into_raw(Box::new(ImageAsset::new())) as jlong
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeGetBytes(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
) -> jbyteArray {
    if asset == 0 {
        return env.new_byte_array(0).unwrap();
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let asset = &mut *asset;
        match asset.get_bytes() {
            Some(bytes) => {
                if let Ok(array) = env.byte_array_from_slice(bytes) {
                    array
                } else {
                    env.new_byte_array(0).unwrap()
                }
            }
            _ => env.new_byte_array(0).unwrap()
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeGetWidth(
    _env: JNIEnv,
    _: JClass,
    asset: jlong,
) -> jint {
    if asset == 0 {
        return 0;
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let asset = &mut *asset;
        asset.width() as i32
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeGetHeight(
    _env: JNIEnv,
    _: JClass,
    asset: jlong,
) -> jint {
    if asset == 0 {
        return 0;
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let asset = &mut *asset;
        asset.height() as i32
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeScale(
    _env: JNIEnv,
    _: JClass,
    asset: jlong,
    x: jint,
    y: jint,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let asset = &mut *asset;
        if asset.scale(x as u32, y as u32) {
            return JNI_TRUE;
        }
        JNI_FALSE
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeFlipX(
    _env: JNIEnv,
    _: JClass,
    _asset: jlong,
) -> jboolean {
    // noop
    JNI_FALSE
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeFlipY(
    _env: JNIEnv,
    _: JClass,
    _asset: jlong,
) -> jboolean {
    // noop
    JNI_FALSE
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeSave(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
    path: JString,
    format: jint,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }
    if let Ok(path) = env.get_string(path) {
        unsafe {
            let asset: *mut ImageAsset = asset as _;
            let asset = &mut *asset;
            if asset.save_path(&path.to_string_lossy(), OutputFormat::from(format)) {
                return JNI_TRUE;
            }
            return JNI_FALSE;
        }
    }
    JNI_FALSE
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeGetError(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
) -> jstring {
    if asset == 0 {
        return env.new_string("").unwrap().into_raw();
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let asset = &mut *asset;
        if let Ok(error) = env.new_string(&asset.error()) {
            return error.into_raw();
        }
        env.new_string("").unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeHasError(
    _env: JNIEnv,
    _: JClass,
    asset: jlong,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let asset = &mut *asset;
        if asset.error().is_empty() {
            return JNI_FALSE;
        }
        JNI_TRUE
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeDestroy(
    _env: JNIEnv,
    _: JClass,
    asset: jlong,
) {
    if asset == 0 {
        return;
    }
    unsafe {
        let asset: *mut ImageAsset = asset as _;
        let _ = Box::from_raw(asset);
    }
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeLoadAssetPath(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
    path: JString,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }
    if let Ok(path) = env.get_string(path) {
        unsafe {
            let asset: *mut ImageAsset = asset as _;
            let asset = &mut *asset;
            if asset.load_from_path(&path.to_string_lossy()) {
                return JNI_TRUE;
            }
            return JNI_FALSE;
        }
    }
    JNI_FALSE
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeLoadAssetBuffer(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
    buffer: JByteBuffer,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }

    match (env.get_direct_buffer_address(buffer), env.get_direct_buffer_capacity(buffer)) {
        (Ok(buf), Ok(len)) => {
            let bytes = unsafe { std::slice::from_raw_parts_mut(buf, len) };
            let asset: *mut ImageAsset = asset as _;
            let asset = unsafe { &mut *asset };
            if asset.load_from_bytes(bytes) {
                return JNI_TRUE;
            }
        }
        _ => {}
    }
    JNI_FALSE
}


#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeLoadAssetBytes(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
    buffer: jbyteArray,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }
    if let Ok(size) = env.get_array_length(buffer) {
        let mut buf = vec![0u8; size as usize];
        unsafe {
            if let Ok(_) =
            env.get_byte_array_region(buffer, 0, std::mem::transmute(buf.as_mut_slice()))
            {
                let asset: *mut ImageAsset = asset as _;
                let asset = &mut *asset;
                if asset.load_from_bytes(buf.as_slice()) {
                    return JNI_TRUE;
                }
            }
        }
    }
    JNI_FALSE
}

#[no_mangle]
pub extern "system" fn Java_org_nativescript_canvas_TNSImageAsset_nativeLoadAssetBitmap(
    env: JNIEnv,
    _: JClass,
    asset: jlong,
    bitmap: JObject,
) -> jboolean {
    if asset == 0 {
        return JNI_FALSE;
    }
    return match crate::android::utils::image::get_bytes_from_bitmap(env, bitmap) {
        Some((bytes, info)) => {
            let asset: *mut ImageAsset = asset as _;
            let asset = unsafe { &mut *asset };


            let mut components = 4; // 32bits

            if info.format() == ndk::bitmap::BitmapFormat::RGB_565 {
                components = 2; // 16bits
            }


            if asset.load_from_bytes_graphics(bytes, info.width() as i32, info.height() as i32, components) {
                return JNI_TRUE;
            }

            return JNI_FALSE;
        }
        _ => JNI_FALSE
    };
}
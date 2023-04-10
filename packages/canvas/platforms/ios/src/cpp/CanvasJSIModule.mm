//
// Created by Osei Fortune on 25/02/2023.
//

#include "CanvasJSIModule.h"
#include "JSICallback.h"
#include "Helpers.h"
#include "JSIReadFileCallback.h"
#include <NativeScript/JSIRuntime.h>

void CanvasJSIModule::install(facebook::jsi::Runtime &jsiRuntime) {
    auto canvas_module = facebook::jsi::Object(jsiRuntime);
    
    CREATE_FUNC("readFile", canvas_module, 2,
                ([](jsi::Runtime &runtime, const jsi::Value &thisValue,
                    const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        auto current_queue = NSOperationQueue.currentQueue;
        
        auto file = arguments[0].asString(runtime).utf8(runtime);
        
        
        auto cbFunc = std::make_shared<jsi::Value>(
                                                   runtime, arguments[1]);
        
        auto jsi_callback = new JSIReadFileCallback(
                                                    std::shared_ptr<jsi::Value>(
                                                                                cbFunc));
        
        
        auto queue = [NSOperationQueue new];
        [queue addOperationWithBlock:^{
            
            
            bool done = false;
            auto ret = canvas_native_helper_read_file(
                                                      rust::Str(file.c_str()));
            
            if (!canvas_native_helper_read_file_has_error(*ret)) {
                auto buf = canvas_native_helper_read_file_get_data(
                                                                   std::move(ret));
                
                auto vec_buffer = std::make_shared<VecMutableBuffer<uint8_t>>(
                                                                              std::move(buf));
                
                jsi_callback->data_ = std::make_shared<jsi::Value>(runtime, jsi::ArrayBuffer(
                                                                                             runtime,
                                                                                             vec_buffer));
                done = true;
            } else {
                auto error = canvas_native_helper_read_file_get_error(
                                                                      *ret);
                
                jsi_callback->data_ = std::make_shared<jsi::Value>(runtime,jsi::String::createFromAscii(
                                                                                                        runtime,
                                                                                                        error.c_str()));
            }
            
            
            
            
            [current_queue addOperationWithBlock:^{
                
                
                auto func = jsi_callback->value_->asObject(
                                                           runtime).asFunction(
                                                                               runtime);
                
                
                
                if (done) {
                    auto buf = jsi_callback->data_->asObject(runtime).getArrayBuffer(runtime);
                    func.call(runtime, {jsi::Value::null(), std::move(buf)});
                } else {
                    auto error = jsi_callback->data_->asString(runtime);
                    func.call(runtime, {std::move(error), jsi::Value::null()});
                }
                
                delete static_cast<JSIReadFileCallback *>(jsi_callback);
                
                
            }];
        }];
        
        return jsi::Value::undefined();
    }
                 
                 )
                
                );
    
    
    CREATE_FUNC("ImageData", canvas_module, 4,
                ([](jsi::Runtime &runtime, const jsi::Value &thisValue,
                    const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        if (arguments[0].isNumber()) {
            auto image_data = canvas_native_context_create_image_data(
                                                                      (int32_t) arguments[0].asNumber(),
                                                                      (int32_t) arguments[1].asNumber());
            auto object = std::make_shared<ImageDataImpl>(std::move(image_data));
            return jsi::Object::createFromHostObject(runtime, std::move(object));
        } else if (arguments[0].isObject()) {
            auto arrayObject = arguments[0].asObject(runtime);
            auto array = arrayObject.getTypedArray(runtime);
            auto buf = GetTypedArrayData<const uint8_t>(runtime, array);
            
            auto image_data = canvas_native_context_create_image_data_with_data(
                                                                                (int32_t) arguments[1].asNumber(),
                                                                                (int32_t) arguments[2].asNumber(), buf);
            auto object = std::make_shared<ImageDataImpl>(std::move(image_data));
            return jsi::Object::createFromHostObject(runtime, std::move(object));
        }
        // TODO throw ?
        return jsi::Value::undefined();
    })
                
                );
    
    
    CREATE_FUNC("ImageAsset", canvas_module, 0,
                ([](jsi::Runtime &runtime, const jsi::Value &thisValue,
                    const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        auto asset = canvas_native_image_asset_create();
        auto object = std::make_shared<ImageAssetImpl>(std::move(asset));
        return jsi::Object::createFromHostObject(runtime, std::move(object));
    })
                
                );
    
    CREATE_FUNC("DOMMatrix", canvas_module, 1,
                ([](jsi::Runtime &runtime, const jsi::Value &thisValue,
                    const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        if (count > 0) {
            if (arguments[0].isObject()) {
                auto initObject = arguments[0].asObject(runtime);
                if (initObject.isArray(runtime)) {
                    auto init = initObject.getArray(runtime);
                    auto size = init.size(runtime);
                    if (size == 6) {
                        auto matrix = canvas_native_matrix_create();
                        rust::Vec<float> buf;
                        buf.reserve(size);
                        for (int i = 0; i < size; i++) {
                            auto item = init.getValueAtIndex(runtime, i).asNumber();
                            buf.emplace_back((float) item);
                        }
                        rust::Slice<const float> slice(buf.data(), buf.size());
                        
                        canvas_native_matrix_update(*matrix, slice);
                        
                        auto object = std::make_shared<MatrixImpl>(std::move(matrix));
                        return jsi::Object::createFromHostObject(runtime,
                                                                 std::move(object));
                    }
                    
                    if (size == 16) {
                        auto matrix = canvas_native_matrix_create();
                        std::array<float, 16> buf;
                        
                        for (int i = 0; i < size; i++) {
                            auto item = init.getValueAtIndex(runtime, i).asNumber();
                            buf[i] = (float) item;
                        }
                        canvas_native_matrix_update_3d(*matrix, buf);
                        
                        auto object = std::make_shared<MatrixImpl>(std::move(matrix));
                        return jsi::Object::createFromHostObject(runtime,
                                                                 std::move(object));
                    }
                }
            }
        } else {
            auto matrix = canvas_native_matrix_create();
            auto object = std::make_shared<MatrixImpl>(std::move(matrix));
            return jsi::Object::createFromHostObject(runtime, std::move(object));
        }
        return jsi::Value::undefined();
    })
                
                );
    
    CREATE_FUNC("Path2D", canvas_module, 1,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        if (count > 0) {
            auto obj = &arguments[0];
            if (obj->isString()) {
                auto d = obj->asString(runtime).utf8(runtime);
                auto path = canvas_native_path_create_with_str(
                                                               rust::Str(d.c_str()));
                auto object = std::make_shared<Path2D>(std::move(path));
                return jsi::Object::createFromHostObject(runtime, std::move(object));
            } else if (obj->isObject()) {
                auto path_to_copy = getHostObject<Path2D>(runtime, arguments[0]);
                if (path_to_copy != nullptr) {
                    auto path = canvas_native_path_create_with_path(
                                                                    path_to_copy->GetPath());
                    auto object = std::make_shared<Path2D>(std::move(path));
                    return jsi::Object::createFromHostObject(runtime,
                                                             std::move(object));
                }
            }
        } else {
            auto path = canvas_native_path_create();
            auto object = std::make_shared<Path2D>(std::move(path));
            return jsi::Object::createFromHostObject(runtime, std::move(object));
        }
        return jsi::Value::undefined();
    }
                
                );
    
    CREATE_FUNC("TextEncoder", canvas_module, 1,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        if (count == 1 && !arguments[0].isString()) {
            auto arg = arguments[0].toString(runtime).utf8(runtime);
            std::string error = "Failed to construct 'TextEncoder': The encoding label provided (" +
            arg + "') is invalid";
            
            throw jsi::JSINativeException(error);
        }
        
        std::string encoding("utf-8");
        if (count == 1) {
            encoding = arguments[0].asString(runtime).utf8(runtime);
        }
        auto encoder = canvas_native_text_encoder_create(
                                                         rust::Str(encoding.c_str()));
        auto shared_encoder = std::make_shared<TextEncoderImpl>(std::move(encoder));
        return jsi::Object::createFromHostObject(runtime, shared_encoder);
    }
                
                );
    
    CREATE_FUNC("TextDecoder", canvas_module, 1,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        if (count == 1 && !arguments[0].isString()) {
            auto arg = arguments[0].toString(runtime).utf8(runtime);
            throw jsi::JSINativeException(
                                          "Failed to construct 'TextDecoder': The encoding label provided (" +
                                          arg + "') is invalid");
        }
        
        std::string encoding("utf-8");
        if (count == 1) {
            encoding = arguments[0].asString(runtime).utf8(runtime);
        }
        auto encoder = canvas_native_text_decoder_create(
                                                         rust::Str(encoding.c_str()));
        auto shared_decoder = std::make_shared<TextDecoderImpl>(std::move(encoder));
        return jsi::Object::createFromHostObject(runtime, shared_decoder);
    }
                
                );
    
    
    CREATE_FUNC("createImageBitmap", canvas_module, 5,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        auto image = &arguments[0];
        auto sx_or_options = &arguments[1];
        auto sy = &arguments[2];
        auto sw = &arguments[3];
        auto sh = &arguments[4];
        
        auto len = count;
        auto cb = &arguments[count - 1];
        len = len - 1;
        
        if (len == 1 && !image->isObject() ||
            image->asObject(runtime).isFunction(runtime)) {
            throw jsi::JSINativeException("Illegal constructor");
        }
        
        Options options;
        
        if (len == 0) {
            throw jsi::JSINativeException("Illegal constructor");
        }
        
        if (!cb->isObject() && !cb->asObject(runtime).isFunction(runtime)) {
            throw jsi::JSINativeException("Illegal constructor");
        }
        
        
        if (image->isNull() || image->isUndefined()) {
            auto error = jsi::String::createFromAscii(
                                                      runtime,
                                                      "Failed to load image");
            cb->asObject(runtime).asFunction(runtime).call(runtime,
                                                           {std::move(error),
                jsi::Value::null()});
            return jsi::Value::undefined();
        }
        
        if (len >= 4 && (sw->isNumber() && sw->asNumber() == 0)) {
            auto error = jsi::String::createFromAscii(runtime,
                                                      "Failed to execute 'createImageBitmap' : The crop rect width is 0");
            cb->asObject(runtime).asFunction(runtime).call(runtime, {std::move(error),
                jsi::Value::undefined()});
            return jsi::Value::undefined();
        }
        if (len >= 5 && (sh->isNumber() && sh->asNumber() == 0)) {
            auto error = jsi::String::createFromAscii(runtime,
                                                      "Failed to execute 'createImageBitmap' : The crop rect height is 0");
            cb->asObject(runtime).asFunction(runtime).call(runtime, {std::move(error),
                jsi::Value::undefined()});
            return jsi::Value::undefined();
        }
        
        auto current_queue = NSOperationQueue.currentQueue;
        
        if (arguments[0].isObject()) {
            auto imageObject = arguments[0].asObject(runtime);
            auto isArrayBuffer = imageObject.isArrayBuffer(runtime);
            auto isTypedArray = imageObject.isTypedArray(runtime);
            if (isArrayBuffer || isTypedArray) {
                
                if (len == 1 || len == 2) {
                    if (len == 2) {
                        options = ImageBitmapImpl::HandleOptions(runtime, arguments[1]);
                    }
                    
                    auto asset = canvas_native_image_asset_create();
                    
                    auto shared_asset = canvas_native_image_asset_shared_clone(*asset);
                    
                    
                    auto ret = std::make_shared<ImageBitmapImpl>(
                                                                 std::move(asset));
                    
                    auto cbFunc = std::make_shared<jsi::Value>(
                                                               runtime, arguments[count - 1]);
                    
                    auto jsi_callback = new JSICallback(
                                                        std::shared_ptr<jsi::Value>(
                                                                                    cbFunc));
                    
                    jsi_callback->data_ = ret;
                    
                    auto ab = std::make_shared<jsi::Value>(runtime,
                                                           std::move(arguments[0]));
                    
                    if (isArrayBuffer) {
                        auto queue = [NSOperationQueue new];
                        [queue addOperationWithBlock:^{
                            
                            
                            auto arrayBuffer = ab->asObject(
                                                            runtime).getArrayBuffer(runtime);
                            
                            auto data = arrayBuffer.data(runtime);
                            auto size = arrayBuffer.size(runtime);
                            
                            
                            auto done = canvas_native_image_bitmap_create_from_encoded_bytes_with_output(
                                                                                                         rust::Slice<const uint8_t>(data, size),
                                                                                                         options.flipY,
                                                                                                         options.premultiplyAlpha,
                                                                                                         options.colorSpaceConversion,
                                                                                                         options.resizeQuality,
                                                                                                         options.resizeWidth,
                                                                                                         options.resizeHeight, ret->GetImageAsset());
                            
                            
                            [current_queue addOperationWithBlock:^{
                                
                                
                                auto func = jsi_callback->value_->asObject(
                                                                           runtime).asFunction(
                                                                                               runtime);
                                
                                if (done) {
                                    
                                    func.call(runtime, {jsi::Value::null(),
                                        jsi::Object::createFromHostObject(
                                                                          runtime,
                                                                          std::move(
                                                                                    jsi_callback->data_))});
                                    
                                } else {
                                    
                                    auto error = jsi::String::createFromAscii(runtime,
                                                                              "Failed to load image");
                                    func.call(runtime,
                                              {std::move(
                                                         error),
                                        jsi::Value::null()});
                                    
                                }
                                
                                delete static_cast<JSICallback *>(jsi_callback);
                                
                                
                            }];
                        }];
                        
                        return jsi::Value::undefined();
                    }
                    
                    if (isTypedArray) {
                        
                        auto queue = [NSOperationQueue new];
                        [queue addOperationWithBlock:^{
                            
                            auto array = ab->asObject(runtime).getTypedArray(
                                                                             runtime);
                            auto data = GetTypedArrayData<const uint8_t>(
                                                                         runtime, array);
                            
                            auto done = canvas_native_image_bitmap_create_from_encoded_bytes_with_output(
                                                                                                         data,
                                                                                                         options.flipY,
                                                                                                         options.premultiplyAlpha,
                                                                                                         options.colorSpaceConversion,
                                                                                                         options.resizeQuality,
                                                                                                         options.resizeWidth,
                                                                                                         options.resizeHeight,
                                                                                                         ret->GetImageAsset());
                            
                            
                            [current_queue addOperationWithBlock:^{
                                
                                
                                
                                
                                auto func = jsi_callback->value_->asObject(
                                                                           runtime).asFunction(
                                                                                               runtime);
                    
                                
                                
                                if (done) {
                                    
                                    func.call(runtime, {jsi::Value::null(),
                                        jsi::Object::createFromHostObject(
                                                                          runtime,
                                                                          std::move(
                                                                                    jsi_callback->data_))});
                                    
                                } else {
                                    
                                    auto error = jsi::String::createFromAscii(runtime,
                                                                              "Failed to load image");
                                    func.call(runtime,
                                              {std::move(
                                                         error),
                                        jsi::Value::null()});
                                    
                                }
                                
                                
                                
                                
                                delete static_cast<JSICallback *>(jsi_callback);
                            }];
                        }];
                        
                    }
                    
                    
                    return jsi::Value::undefined();
                } else if (len == 5 || len == 6) {
                    
                    auto cbFunc = std::make_shared<jsi::Value>(
                                                               runtime, arguments[count - 1]);
                    
                    if (len == 6) {
                        options = ImageBitmapImpl::HandleOptions(runtime, arguments[5]);
                    }
                    
                    auto asset = canvas_native_image_asset_create();
                    
                    auto shared_asset = canvas_native_image_asset_shared_clone(*asset);
                    
                    auto ret = std::make_shared<ImageBitmapImpl>(
                                                                 std::move(asset));
                    
                    auto jsi_callback = new JSICallback(
                                                        std::shared_ptr<jsi::Value>(
                                                                                    cbFunc));
                    
                    jsi_callback->data_ = std::move(ret);
                    
                    auto ab = std::make_shared<jsi::Value>(runtime,
                                                           std::move(arguments[0]));
                    
                    
                    if (isArrayBuffer) {
                        
                        auto queue = [NSOperationQueue new];
                        [queue addOperationWithBlock:^{
                            
                            
                            auto arrayBuffer = ab->asObject(
                                                            runtime).getArrayBuffer(runtime);
                            
                            auto data = arrayBuffer.data(runtime);
                            auto size = arrayBuffer.size(runtime);
                            
                            auto done = canvas_native_image_bitmap_create_from_encoded_bytes_src_rect_with_output(
                                                                                                                  rust::Slice<const uint8_t>(data, size),
                                                                                                                  (float) sx_or_options->asNumber(),
                                                                                                                  (float) sy->asNumber(),
                                                                                                                  (float) sw->asNumber(),
                                                                                                                  (float) sh->asNumber(),
                                                                                                                  options.flipY,
                                                                                                                  options.premultiplyAlpha,
                                                                                                                  options.colorSpaceConversion,
                                                                                                                  options.resizeQuality,
                                                                                                                  options.resizeWidth,
                                                                                                                  options.resizeHeight, ret->GetImageAsset());
                            
                            
                            [current_queue addOperationWithBlock:^{
                                
                                auto func = jsi_callback->value_->asObject(
                                                                           runtime).asFunction(
                                                                                               runtime);
                                
                                
                                if (done) {
                                    
                                    func.call(runtime, {jsi::Value::null(),
                                        jsi::Object::createFromHostObject(
                                                                          runtime,
                                                                          std::move(
                                                                                    jsi_callback->data_))});
                                    
                                } else {
                                    
                                    auto error = jsi::String::createFromAscii(runtime,
                                                                              "Failed to load image");
                                    func.call(runtime,
                                              {std::move(
                                                         error),
                                        jsi::Value::null()});
                                    
                                }
                                
                                
                               
                                
                                delete static_cast<JSICallback *>(jsi_callback);
                            }];
                        }];
                        
                        
                        return jsi::Value::undefined();
                    }
                    
                    if (isTypedArray) {
                        
                        auto queue = [NSOperationQueue new];
                        [queue addOperationWithBlock:^{
                            
                            auto array = ab->asObject(runtime).getTypedArray(
                                                                             runtime);
                            auto data = GetTypedArrayData<const uint8_t>(
                                                                         runtime, array);
                            
                            auto done = canvas_native_image_bitmap_create_from_encoded_bytes_src_rect_with_output(
                                                                                                                  data,
                                                                                                                  (float) sx_or_options->asNumber(),
                                                                                                                  (float) sy->asNumber(),
                                                                                                                  (float) sw->asNumber(),
                                                                                                                  (float) sh->asNumber(),
                                                                                                                  options.flipY,
                                                                                                                  options.premultiplyAlpha,
                                                                                                                  options.colorSpaceConversion,
                                                                                                                  options.resizeQuality,
                                                                                                                  options.resizeWidth,
                                                                                                                  options.resizeHeight, ret->GetImageAsset());
                            
                            [current_queue addOperationWithBlock:^{
                                
                                
                                
                                
                                auto func = jsi_callback->value_->asObject(
                                                                           runtime).asFunction(
                                                                                               runtime);
                                
                                
                                if (done) {
                                    
                                    func.call(runtime, {jsi::Value::null(),
                                        jsi::Object::createFromHostObject(
                                                                          runtime,
                                                                          std::move(
                                                                                    jsi_callback->data_))});
                                    
                                } else {
                                    
                                    auto error = jsi::String::createFromAscii(runtime,
                                                                              "Failed to load image");
                                    func.call(runtime,
                                              {std::move(
                                                         error),
                                        jsi::Value::null()});
                                    
                                }
                                
                                
                                delete static_cast<JSICallback *>(jsi_callback);
                            }];
                        }];
                        
                    }
                    
                    
                    
                    return jsi::Value::undefined();
                }
            }
        }
        
        
        auto image_asset = getHostObject<ImageAssetImpl>(
                                                         runtime, arguments[0]);
        
        auto image_bitmap = getHostObject<ImageBitmapImpl>(
                                                           runtime, arguments[0]);
        
        if (len == 1 || len == 2) {
            if (len == 2) {
                options = ImageBitmapImpl::HandleOptions(runtime, arguments[1]);
            }
            
            
            auto ret = canvas_native_image_bitmap_create_from_asset(
                                                                    image_asset != nullptr ? image_asset->GetImageAsset()
                                                                    : image_bitmap->GetImageAsset(),
                                                                    options.flipY,
                                                                    options.premultiplyAlpha,
                                                                    options.colorSpaceConversion,
                                                                    options.resizeQuality,
                                                                    options.resizeWidth,
                                                                    options.resizeHeight);
            
            
            auto bitmap = std::make_shared<ImageBitmapImpl>(std::move(ret));
            
            auto bitmap_object = jsi::Object::createFromHostObject(runtime, bitmap);
            
            cb->asObject(runtime).asFunction(runtime).call(runtime, {jsi::Value::null(),
                std::move(
                          bitmap_object)});
            
            return jsi::Value::undefined();
        } else if (len == 5 || len == 6) {
            
            if (len == 6) {
                options = ImageBitmapImpl::HandleOptions(runtime, arguments[5]);
            }
            
            auto ret = canvas_native_image_bitmap_create_from_asset_src_rect(
                                                                             image_asset != nullptr ? image_asset->GetImageAsset()
                                                                             : image_bitmap->GetImageAsset(),
                                                                             (float) sx_or_options->asNumber(),
                                                                             (float) sy->asNumber(),
                                                                             (float) sw->asNumber(),
                                                                             (float) sh->asNumber(),
                                                                             options.flipY,
                                                                             options.premultiplyAlpha,
                                                                             options.colorSpaceConversion,
                                                                             options.resizeQuality,
                                                                             options.resizeWidth,
                                                                             options.resizeHeight);
            
            auto bitmap = std::make_shared<ImageBitmapImpl>(std::move(ret));
            
            auto bitmap_object = jsi::Object::createFromHostObject(runtime, bitmap);
            
            cb->asObject(runtime).asFunction(runtime).call(runtime, {jsi::Value::null(),
                std::move(
                          bitmap_object)});
            
            return jsi::Value::undefined();
        }
        
        
        return jsi::Value::undefined();
    }
                
                );
    
    CREATE_FUNC("create2DContext", canvas_module, 9,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        auto context = getPointerValue(runtime, arguments[0]);
        auto width = (float) arguments[1].asNumber();
        auto height = (float) arguments[2].asNumber();
        auto density = (float) arguments[3].asNumber();
        auto samples = (int) arguments[4].asNumber();
        auto alpha = (bool) arguments[5].asBool();
        auto font_color = (int) arguments[6].asNumber();
        auto ppi = (float) arguments[7].asNumber();
        auto direction = (int) arguments[8].asNumber();
        
        auto context_2d = canvas_native_context_create_gl(width, height, density,
                                                          context,
                                                          samples, alpha,
                                                          font_color, ppi, direction);
        
        auto ret = std::make_shared<CanvasRenderingContext2DImpl>(
                                                                  std::move(context_2d));
        
        return jsi::Object::createFromHostObject(runtime, ret);
    }
                
                );
    
    CREATE_FUNC("create2DContextWithPointer", canvas_module, 1,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        auto pointer = getPointerValue(runtime, arguments[0]);
        
        auto context_2d = canvas_native_context_create_with_pointer(pointer);
        
        auto ret = std::make_shared<CanvasRenderingContext2DImpl>(
                                                                  std::move(context_2d));
        
        return jsi::Object::createFromHostObject(runtime, ret);
    }
                
                );
    
    CREATE_FUNC("createWebGLContext", canvas_module, 7,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        if (arguments[0].isObject()) {
            auto config = arguments[0].asObject(runtime);
            std::string version("none");
            auto alpha = true;
            auto antialias = true;
            auto depth = true;
            auto fail_if_major_performance_caveat = false;
            std::string power_preference("default");
            auto premultiplied_alpha = true;
            auto preserve_drawing_buffer = false;
            auto stencil = false;
            auto desynchronized = false;
            auto xr_compatible = false;
            
            
            auto versionValue = config.getProperty(runtime, "version");
            if (versionValue.isString()) {
                version = versionValue.asString(runtime).utf8(runtime);
            }
            
            auto alphaValue = config.getProperty(runtime, "alpha");
            if (alphaValue.isBool()) {
                alpha = alphaValue.asBool();
            }
            
            auto antialiasValue = config.getProperty(runtime, "antialias");
            if (antialiasValue.isBool()) {
                antialias = antialiasValue.asBool();
            }
            
            auto failIfMajorPerformanceCaveatValue = config.getProperty(runtime,
                                                                        "failIfMajorPerformanceCaveat");
            if (failIfMajorPerformanceCaveatValue.isBool()) {
                fail_if_major_performance_caveat = failIfMajorPerformanceCaveatValue.asBool();
            }
            
            auto powerPreferenceValue = config.getProperty(runtime, "powerPreference");
            if (powerPreferenceValue.isString()) {
                power_preference = powerPreferenceValue.asString(runtime).utf8(runtime);
            }
            
            auto premultipliedAlphaValue = config.getProperty(runtime,
                                                              "premultipliedAlpha");
            if (premultipliedAlphaValue.isBool()) {
                premultiplied_alpha = premultipliedAlphaValue.asBool();
            }
            
            auto preserveDrawingBufferValue = config.getProperty(runtime,
                                                                 "preserveDrawingBuffer");
            if (preserveDrawingBufferValue.isBool()) {
                preserve_drawing_buffer = preserveDrawingBufferValue.asBool();
            }
            
            auto stencilValue = config.getProperty(runtime, "stencil");
            if (stencilValue.isBool()) {
                stencil = stencilValue.asBool();
            }
            
            auto desynchronizedValue = config.getProperty(runtime, "desynchronized");
            if (desynchronizedValue.isBool()) {
                desynchronized = desynchronizedValue.asBool();
            }
            
            auto xrCompatibleValue = config.getProperty(
                                                        runtime,
                                                        "xrCompatible");
            if (xrCompatibleValue.isBool()) {
                xr_compatible = xrCompatibleValue.asBool();
            }
            
            if (version !=
                "v1") {
                return jsi::Value::undefined();
            } else {
                if (count == 6) {
                    auto context = getPointerValue(runtime, arguments[1]);
//                    auto density = arguments[2].asNumber();
//                    auto fontColor = arguments[3].asNumber();
//                    auto ppi = arguments[4].asNumber();
//                    auto direction = arguments[5].asNumber();
                    auto ctx = canvas_native_webgl_create(
                                                          context,
                                                          rust::Str(
                                                                    version.c_str()),
                                                          alpha,
                                                          antialias,
                                                          depth,
                                                          fail_if_major_performance_caveat,
                                                          rust::Str(
                                                                    power_preference.c_str()),
                                                          premultiplied_alpha,
                                                          preserve_drawing_buffer,
                                                          stencil,
                                                          desynchronized,
                                                          xr_compatible
                                                          );
                    
                    auto renderingContext = std::make_shared<WebGLRenderingContext>(
                                                                                    std::move(ctx));
                    
                    return jsi::Object::createFromHostObject(
                                                             runtime, renderingContext);
                    
                } else if (count == 7) {
                    auto width = arguments[1].asNumber();
                    auto height = arguments[2].asNumber();
//                    auto density = arguments[3].asNumber();
//                    auto fontColor = arguments[4].asNumber();
//                    auto ppi = arguments[5].asNumber();
//                    auto direction = arguments[6].asNumber();
                    auto ctx = canvas_native_webgl_create_no_window(
                                                                    (int32_t) width,
                                                                    (int32_t) height,
                                                                    rust::Str(
                                                                              version.c_str()),
                                                                    alpha,
                                                                    antialias,
                                                                    depth,
                                                                    fail_if_major_performance_caveat,
                                                                    rust::Str(
                                                                              power_preference.c_str()),
                                                                    premultiplied_alpha,
                                                                    preserve_drawing_buffer,
                                                                    stencil,
                                                                    desynchronized,
                                                                    xr_compatible,
                                                                    false
                                                                    );
                    
                    auto renderingContext = std::make_shared<WebGLRenderingContext>(
                                                                                    std::move(ctx));
                    
                    return jsi::Object::createFromHostObject(
                                                             runtime, renderingContext);
                    
                } else {
                    auto width = (int32_t) arguments[1].asNumber();
                    auto height = (int32_t) arguments[2].asNumber();
                    
                    auto ctx = canvas_native_webgl_create_no_window(
                                                                    width,
                                                                    height,
                                                                    rust::Str(
                                                                              version.c_str()),
                                                                    alpha,
                                                                    antialias,
                                                                    depth,
                                                                    fail_if_major_performance_caveat,
                                                                    rust::Str(
                                                                              power_preference.c_str()),
                                                                    premultiplied_alpha,
                                                                    preserve_drawing_buffer,
                                                                    stencil,
                                                                    desynchronized,
                                                                    xr_compatible,
                                                                    false
                                                                    );
                    
                    auto renderingContext = std::make_shared<WebGLRenderingContext>(
                                                                                    std::move(
                                                                                              ctx));
                    
                    
                    return jsi::Object::createFromHostObject(
                                                             runtime,
                                                             renderingContext);
                }
                
            }
        }
        
        
        return jsi::Value::undefined();
    }
                
                );
    
    CREATE_FUNC("createWebGL2Context", canvas_module, 7,
                [](jsi::Runtime &runtime, const jsi::Value &thisValue,
                   const jsi::Value *arguments, size_t count) -> jsi::Value {
        
        if (arguments[0].isObject()) {
            auto config = arguments[0].asObject(runtime);
            std::string version("none");
            auto alpha = true;
            auto antialias = true;
            auto depth = true;
            auto fail_if_major_performance_caveat = false;
            std::string power_preference("default");
            auto premultiplied_alpha = true;
            auto preserve_drawing_buffer = false;
            auto stencil = false;
            auto desynchronized = false;
            auto xr_compatible = false;
            
            
            auto versionValue = config.getProperty(runtime, "version");
            if (versionValue.isString()) {
                version = versionValue.asString(runtime).utf8(runtime);
            }
            
            auto alphaValue = config.getProperty(runtime, "alpha");
            if (alphaValue.isBool()) {
                alpha = alphaValue.asBool();
            }
            
            auto antialiasValue = config.getProperty(runtime, "antialias");
            if (antialiasValue.isBool()) {
                antialias = antialiasValue.asBool();
            }
            
            auto failIfMajorPerformanceCaveatValue = config.getProperty(runtime,
                                                                        "failIfMajorPerformanceCaveat");
            if (failIfMajorPerformanceCaveatValue.isBool()) {
                fail_if_major_performance_caveat = failIfMajorPerformanceCaveatValue.asBool();
            }
            
            auto powerPreferenceValue = config.getProperty(runtime, "powerPreference");
            if (powerPreferenceValue.isString()) {
                power_preference = powerPreferenceValue.asString(runtime).utf8(runtime);
            }
            
            auto premultipliedAlphaValue = config.getProperty(runtime,
                                                              "premultipliedAlpha");
            if (premultipliedAlphaValue.isBool()) {
                premultiplied_alpha = premultipliedAlphaValue.asBool();
            }
            
            auto preserveDrawingBufferValue = config.getProperty(runtime,
                                                                 "preserveDrawingBuffer");
            if (preserveDrawingBufferValue.isBool()) {
                preserve_drawing_buffer = preserveDrawingBufferValue.asBool();
            }
            
            auto stencilValue = config.getProperty(runtime, "stencil");
            if (stencilValue.isBool()) {
                stencil = stencilValue.asBool();
            }
            
            auto desynchronizedValue = config.getProperty(runtime, "desynchronized");
            if (desynchronizedValue.isBool()) {
                desynchronized = desynchronizedValue.asBool();
            }
            
            auto xrCompatibleValue = config.getProperty(
                                                        runtime,
                                                        "xrCompatible");
            if (xrCompatibleValue.isBool()) {
                xr_compatible = xrCompatibleValue.asBool();
            }
            
            if (version !=
                "v2") {
                return jsi::Value::undefined();
            } else {
                if (count == 6) {
                    auto context = getPointerValue(runtime, arguments[1]);
//                    auto density = arguments[2].asNumber();
//                    auto fontColor = arguments[3].asNumber();
//                    auto ppi = arguments[4].asNumber();
//                    auto direction = arguments[5].asNumber();
                    auto ctx = canvas_native_webgl_create(
                                                          context,
                                                          rust::Str(
                                                                    version.c_str()),
                                                          alpha,
                                                          antialias,
                                                          depth,
                                                          fail_if_major_performance_caveat,
                                                          rust::Str(
                                                                    power_preference.c_str()),
                                                          premultiplied_alpha,
                                                          preserve_drawing_buffer,
                                                          stencil,
                                                          desynchronized,
                                                          xr_compatible
                                                          );
                    
                    auto renderingContext = std::make_shared<WebGL2RenderingContext>(
                                                                                     std::move(ctx), WebGLRenderingVersion::V2);
                    
                    return jsi::Object::createFromHostObject(
                                                             runtime, renderingContext);
                    
                } else if (count ==
                           7) {
                    auto width = arguments[1].asNumber();
                    auto height = arguments[2].asNumber();
//                    auto density = arguments[3].asNumber();
//                    auto fontColor = arguments[4].asNumber();
//                    auto ppi = arguments[5].asNumber();
//                    auto direction = arguments[6].asNumber();
                    auto ctx = canvas_native_webgl_create_no_window(
                                                                    (int32_t) width,
                                                                    (int32_t) height,
                                                                    rust::Str(
                                                                              version.c_str()),
                                                                    alpha,
                                                                    antialias,
                                                                    depth,
                                                                    fail_if_major_performance_caveat,
                                                                    rust::Str(
                                                                              power_preference.c_str()),
                                                                    premultiplied_alpha,
                                                                    preserve_drawing_buffer,
                                                                    stencil,
                                                                    desynchronized,
                                                                    xr_compatible,
                                                                    false
                                                                    );
                    auto renderingContext = std::make_shared<WebGL2RenderingContext>(
                                                                                     std::move(
                                                                                               ctx), WebGLRenderingVersion::V2);
                    
                    return jsi::Object::createFromHostObject(
                                                             runtime,
                                                             renderingContext);
                    
                } else {
                    auto width = (int32_t) arguments[1].asNumber();
                    auto height = (int32_t) arguments[2].asNumber();
                    auto ctx = canvas_native_webgl_create_no_window(
                                                                    width,
                                                                    height,
                                                                    rust::Str(
                                                                              version.c_str()),
                                                                    alpha,
                                                                    antialias,
                                                                    depth,
                                                                    fail_if_major_performance_caveat,
                                                                    rust::Str(
                                                                              power_preference.c_str()),
                                                                    premultiplied_alpha,
                                                                    preserve_drawing_buffer,
                                                                    stencil,
                                                                    desynchronized,
                                                                    xr_compatible,
                                                                    false
                                                                    );
                    
                    auto renderingContext = std::make_shared<WebGL2RenderingContext>(
                                                                                     std::move(
                                                                                               ctx), WebGLRenderingVersion::V2);
                    
                    return jsi::Object::createFromHostObject(
                                                             runtime,
                                                             renderingContext);
                }
            }
        }
        
        return jsi::Value::undefined();
    }
                
                );
    
    auto global = jsiRuntime.global();
    
    if (!global.
        hasProperty(jsiRuntime,
                    "CanvasJSIModule")) {
        global.
        setProperty(jsiRuntime,
                    "CanvasJSIModule", canvas_module);
    }
}
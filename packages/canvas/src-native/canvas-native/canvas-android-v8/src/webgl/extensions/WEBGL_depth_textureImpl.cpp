//
// Created by Osei Fortune on 29/04/2022.
//

#include "WEBGL_depth_textureImpl.h"
#include "canvas-android-v8/src/bridges/context.rs.h"

v8::Local<v8::FunctionTemplate> WEBGL_depth_textureImpl::GetCtor(v8::Isolate *isolate) {
    auto cache = Caches::Get(isolate);
    auto ctor = cache->WEBGL_depth_textureImplTmpl.get();
    if (ctor != nullptr) {
        return ctor->Get(isolate);
    }
    v8::Local<v8::FunctionTemplate> ctorTmpl = v8::FunctionTemplate::New(isolate);
    ctorTmpl->SetClassName(Helpers::ConvertToV8String(isolate, "WEBGL_depth_texture"));
    cache->WEBGL_depth_textureImplTmpl = std::make_unique<v8::Persistent<v8::FunctionTemplate>>(isolate, ctorTmpl);
    return ctorTmpl;
}

v8::Local<v8::Object> WEBGL_depth_textureImpl::NewInstance(v8::Isolate *isolate) {
    v8::Locker locker(isolate);
    v8::Isolate::Scope isolate_scope(isolate);
    v8::EscapableHandleScope handle_scope(isolate);
    auto context = isolate->GetCurrentContext();
    auto ctorFunc = GetCtor(isolate);
    auto result = ctorFunc->InstanceTemplate()->NewInstance(context).ToLocalChecked();
    Helpers::SetInternalClassName(isolate, result, "WEBGL_depth_texture");
    result->Set(context, Helpers::ConvertToV8String(isolate, "UNSIGNED_INT_24_8_WEBGL"),
                v8::Int32::New(isolate, 0x84FA));
    return handle_scope.Escape(result);
}
//
// Created by Osei Fortune on 27/03/2022.
//

#pragma once
#include "../Common.h"
#include "../Caches.h"
#include "../Helpers.h"

class ImageDataImpl {
public:
    ImageDataImpl(rust::Box<ImageData> imageData);

    ~ImageDataImpl();

    static void Init(v8::Isolate *isolate);

    static void Create(const v8::FunctionCallbackInfo<v8::Value> &args);

    static void GetWidth(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value> &info);

    static void GetHeight(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value> &info);

    static void GetData(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value> &info);

    static ImageDataImpl *GetPointer(const v8::Local<v8::Object>& object);

    static v8::Local<v8::Object> NewInstance(v8::Isolate* isolate, ImageDataImpl* imageData);

    ImageData& GetImageData();
    const float GetWidth();
    const float GetHeight();

    template<typename T>
    static void AddWeakListener(v8::Isolate *isolate, const v8::Local<v8::Object> &object, T *data){
        auto ext = v8::External::New(isolate, data);
        object->SetInternalField(0, ext);
        auto persistent = new v8::Persistent<v8::Object>(isolate, object);
        auto entry = new ObjectCacheEntry(static_cast<void *>(data), persistent);
        auto callback = [](const v8::WeakCallbackInfo<ObjectCacheEntry> &cacheEntry) {
            auto value = cacheEntry.GetParameter();
            auto ptr = static_cast<T *>(value->data);
            if (ptr != nullptr) {
                delete ptr;
            }
            auto persistent_ptr = value->object;
            if (persistent_ptr != nullptr) {
                if (!persistent_ptr->IsEmpty()) {
                    persistent_ptr->Reset();
                }
            }
            delete value;
        };
        persistent->SetWeak(entry, callback, v8::WeakCallbackType::kFinalizer);
    }
private:
    rust::Box<ImageData> imageData_;
    std::shared_ptr<v8::Persistent<v8::Object>> buffer_;
    static v8::Local<v8::FunctionTemplate> GetCtor(v8::Isolate *isolate);
};

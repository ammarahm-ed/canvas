//
// Created by Osei Fortune on 29/04/2022.
//

#include "WEBGL_compressed_texture_etc1Impl.h"

jsi::Value
WEBGL_compressed_texture_etc1Impl::get(jsi::Runtime &runtime, const jsi::PropNameID &name) {
    auto methodName = name.utf8(runtime);
    if (methodName == "COMPRESSED_RGB_ETC1_WEBGL") {
        return {GL_ETC1_RGB8_OES};
    }

    return jsi::Value::undefined();
}

std::vector<jsi::PropNameID> WEBGL_compressed_texture_etc1Impl::getPropertyNames(jsi::Runtime &rt) {
    return {
            jsi::PropNameID::forUtf8(rt, std::string("COMPRESSED_RGB_ETC1_WEBGL"))
    };
}

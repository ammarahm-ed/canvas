//
// Created by Osei Fortune on 29/04/2022.
//

#include "OES_standard_derivativesImpl.h"

std::vector<jsi::PropNameID> OES_standard_derivativesImpl::getPropertyNames(jsi::Runtime &rt) {
    std::vector<jsi::PropNameID> ret;
    ret.emplace_back(
            jsi::PropNameID::forUtf8(rt, std::string("FRAGMENT_SHADER_DERIVATIVE_HINT_OES")));

    ret.emplace_back(
            jsi::PropNameID::forUtf8(rt, std::string("ext_name")));

    return ret;
}


jsi::Value OES_standard_derivativesImpl::get(jsi::Runtime &runtime, const jsi::PropNameID &name) {
    auto methodName = name.utf8(runtime);

    if (methodName == "ext_name") {
        return jsi::String::createFromAscii(runtime, "OES_standard_derivatives");
    }

    if (methodName == "FRAGMENT_SHADER_DERIVATIVE_HINT_OES") {
        return {GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES};
    }

    return jsi::Value::undefined();
}
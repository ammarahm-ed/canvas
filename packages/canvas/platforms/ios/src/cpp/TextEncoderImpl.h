//
// Created by Osei Fortune on 19/04/2022.
//

#pragma once

#include "rust/cxx.h"
#include "canvas-cxx/src/lib.rs.h"
#include "VecMutableBuffer.h"
#include <vector>

using namespace facebook;
using namespace org::nativescript::canvas;

class JSI_EXPORT TextEncoderImpl : public jsi::HostObject {

public:
    TextEncoderImpl(rust::Box<TextEncoder> encoder);

    jsi::Value get(jsi::Runtime &, const jsi::PropNameID &name) override;

    std::vector<jsi::PropNameID> getPropertyNames(jsi::Runtime &rt) override;

    TextEncoder &GetTextEncoder();

private:
    rust::Box<TextEncoder> encoder_;
};
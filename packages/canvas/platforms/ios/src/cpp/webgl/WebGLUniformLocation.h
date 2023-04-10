//
// Created by Osei Fortune on 27/04/2022.
//

#pragma once

#include "rust/cxx.h"
#include "canvas-cxx/src/lib.rs.h"
#import <NativeScript/JSIRuntime.h>

using namespace facebook;


class JSI_EXPORT WebGLUniformLocation

        : public jsi::HostObject {
public:
    WebGLUniformLocation(int32_t
                         uniformLocation) :
            uniformLocation_(uniformLocation) {}

    int32_t GetUniformLocation() {
        return this->uniformLocation_;
    }

private:
    int32_t uniformLocation_;
};
//
// Created by Osei Fortune on 03/04/2022.
//

#pragma once

#include "rust/cxx.h"
#include "canvas-cxx/src/canvas2d.rs.h"
#import "v8runtime/V8Runtime.h"

using namespace facebook;

class JSI_EXPORT MatrixImpl : jsi::HostObject {
public:
    MatrixImpl(rust::Box<Matrix> matrix);

    jsi::Value get(jsi::Runtime &, const jsi::PropNameID &name) override;

    void set(jsi::Runtime &, const jsi::PropNameID &name, const jsi::Value &value) override;

    std::vector<jsi::PropNameID> getPropertyNames(jsi::Runtime &rt) override;

    Matrix &GetMatrix();

private:
    rust::Box<Matrix> matrix_;
};

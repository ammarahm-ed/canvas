//
// Created by Osei Fortune on 28/04/2022.
//

#pragma once

#include "rust/cxx.h"
#include "canvas-cxx/src/lib.rs.h"
#import <NativeScript/JSIRuntime.h>
#include "webgl2/WebGLQuery.h"
#include <vector>

using namespace facebook;
using namespace org::nativescript::canvas;

class JSI_EXPORT EXT_disjoint_timer_queryImpl : public jsi::HostObject {
public:
    EXT_disjoint_timer_queryImpl(rust::Box<EXT_disjoint_timer_query> query);

    jsi::Value get(jsi::Runtime &, const jsi::PropNameID &name) override;

    std::vector<jsi::PropNameID> getPropertyNames(jsi::Runtime &rt) override;

    EXT_disjoint_timer_query &GetQuery();

private:
    rust::Box<EXT_disjoint_timer_query> query_;
};
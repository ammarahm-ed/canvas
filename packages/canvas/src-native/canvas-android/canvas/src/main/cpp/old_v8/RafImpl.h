//
// Created by Osei Fortune on 20/04/2022.
//

#ifndef CANVAS_NATIVE_RAFIMPL_H
#define CANVAS_NATIVE_RAFIMPL_H
#include "Common.h"
#include "OnRafCallback.h"

class RafImpl {
public:
    RafImpl(OnRafCallback* rafCallback, intptr_t callback, rust::Box<Raf> raf);

    Raf& GetRaf();
private:
    OnRafCallback* rafCallback_;
    intptr_t callback_;
    rust::Box<::Raf> raf_;
};


#endif //CANVAS_NATIVE_RAFIMPL_H
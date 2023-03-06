fn main() {
    let mut bridges: Vec<&str> = vec![];

    #[cfg(feature = "2d")]
    bridges.push("src/canvas2d.rs");

    #[cfg(feature = "webgl")]
    bridges.push("src/webgl.rs");

    #[cfg(feature = "webgl")]
    bridges.push("src/webgl2.rs");

    #[cfg(feature = "webgl")]
    bridges.push("src/constants.rs");

    if !bridges.is_empty() {
        let _ = cxx_build::bridges(bridges.as_slice())
            .flag_if_supported("-std=c++17");
    }
}

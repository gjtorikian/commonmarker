fn main() {
    // Ruby statically bundles Oniguruma in its Windows library (libx64-ucrt-ruby*.a),
    // which collides with onig_sys pulled in by comrak's syntect dependency.
    // Allow the linker to resolve duplicates by picking the first definition.
    let target = std::env::var("TARGET").unwrap_or_default();
    if target.contains("windows-gnu") {
        println!("cargo:rustc-link-arg=-Wl,--allow-multiple-definition");
    }
}

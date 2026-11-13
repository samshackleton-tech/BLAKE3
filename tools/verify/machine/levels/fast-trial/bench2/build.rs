// The proved functions of levels.ode as assembly, printed by Lean from the source (kept beside as hashf.S):
// hashf and everything it calls of ours. The two wide kernels it calls are the library's own.
fn main() {
    cc::Build::new().file("../hashf.S").compile("hashf_ode");
    println!("cargo::rerun-if-changed=../hashf.S");
}

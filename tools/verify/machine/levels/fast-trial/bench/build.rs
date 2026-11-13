// The trial's functions as assembly, printed by Lean from levels_trial.ode (kept beside it as trial.S).
fn main() {
    cc::Build::new().file("../trial.S").compile("fast_trial");
    println!("cargo::rerun-if-changed=../trial.S");
}

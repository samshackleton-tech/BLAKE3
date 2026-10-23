//! Additional visibility controls for the unchanged finish source and a
//! paired copy whose completion-count load is Acquire. Assertions read the
//! worker outputs immediately after wait, BEFORE joining the workers.
#![allow(dead_code, unexpected_cfgs)]
mod finish_sync {
    pub use loom::sync::atomic::{AtomicUsize, Ordering};
    pub use loom::sync::Mutex;
    pub use loom::thread;
}
#[path = "../finish-original.rs"]
mod original;
#[path = "../finish-acquire.rs"]
mod acquire;

use loom::sync::atomic::{AtomicUsize, Ordering};
use loom::sync::Arc;
use loom::thread;

macro_rules! visibility_control {
    ($name:ident, $module:ident, $pieces:expr) => {
        #[test]
        fn $name() {
            loom::model(|| {
                let finish = Arc::new($module::Finish::new());
                let outputs = Arc::new((0..$pieces).map(|_| AtomicUsize::new(0)).collect::<Vec<_>>());
                finish.published.store($pieces, Ordering::SeqCst);
                finish.own();
                let workers: Vec<_> = (0..$pieces).map(|i| {
                    let (f, out) = (finish.clone(), outputs.clone());
                    thread::spawn(move || {
                        out[i].store(i + 1, Ordering::Relaxed);
                        f.finished(1);
                    })
                }).collect();
                finish.wait($pieces, || false);
                for i in 0..$pieces {
                    assert_eq!(outputs[i].load(Ordering::Relaxed), i + 1,
                        "wait returned without publishing worker output {i}");
                }
                // Joining earlier would itself acquire the output writes,
                // masking a missing acquire in Finish::wait.
                for w in workers { w.join().unwrap(); }
            });
        }
    }
}
visibility_control!(original_one_worker, original, 1);
visibility_control!(original_two_workers, original, 2);
visibility_control!(acquire_one_worker, acquire, 1);
visibility_control!(acquire_two_workers, acquire, 2);

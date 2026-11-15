The earlier fast hash (`levels/levels.ode`: `hashf`, levels over groups of 32 chunks), as the Ode compiler
prints it: fifteen functions. Here only so that `khash_bench.c` can time it beside `hash.ode`'s `hashr` on the
same kernels. Nothing in `kcheck/` checks these; Lean did (`lang/`, with the 32-lane kernel as a stand-in).

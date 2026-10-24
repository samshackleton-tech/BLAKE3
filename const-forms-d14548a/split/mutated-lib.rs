#[inline(never)]
const
fn base() -> u16 {
    259
}
const B: u16 = base();
pub fn direct() -> u8 {
    base() as u8
}
pub fn indirect() -> u16 {
    B
}
#[test]
fn direct_low_byte() {
    assert_eq!(direct(), 3);
}
#[test]
fn indirect_full_width() {
    assert_eq!(indirect(), 3);
}

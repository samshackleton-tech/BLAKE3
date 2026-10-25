fn main() {
    b3::initialize_multithreaded(None);
    let lengths = [0, 1, 63, 64, 65, 1023, 1024, 1025, 1536, 4096, 16385, 524289];
    let data: Vec<u8> = (0..=524289).map(|i| (i % 251) as u8).collect();
    let key = [42u8; 32];
    let context = "servil packaged-consumer release preflight";
    for len in lengths {
        // Deliberately offset: convenience calls accept arbitrary slices.
        let input = &data[1..][..len];
        let expected = official::hash(input);
        assert_eq!(b3::hash(input).as_bytes(), expected.as_bytes());
        assert_eq!(b3::hash_multithreaded(input).as_bytes(), expected.as_bytes());
        assert_eq!(b3::hash_with(b3::Mode::Keyed(&key), input).as_bytes(), official::keyed_hash(&key, input).as_bytes());
        assert_eq!(b3::hash_with(b3::Mode::DeriveKey(context), input).as_bytes(), &official::derive_key(context, input));
        let mut a = b3::Hasher::new();
        let mut b = official::Hasher::new();
        for part in input.chunks(65) {
            a.update(part);
            b.update(part);
        }
        assert_eq!(a.finalize().as_bytes(), b.finalize().as_bytes());
        let mut ax = a.finalize_xof();
        let mut bx = b.finalize_xof();
        let mut ao = [0u8; 129];
        let mut bo = [0u8; 129];
        ax.set_position(31);
        bx.set_position(31);
        ax.fill(&mut ao);
        bx.fill(&mut bo);
        assert_eq!(ao, bo);
    }
    let counts = [1, 2, 4, 8, 16, 17];
    for count in counts {
        let input = &data[1..][..count * 64];
        let mut out = vec![[0u8; 32]; count];
        b3::hash_many(input, 64, &mut out);
        for (message, digest) in input.chunks_exact(64).zip(out.iter()) {
            assert_eq!(digest, official::hash(message).as_bytes());
        }
    }
    println!("packaged consumer: {} lengths, modes, incremental/XOF and {} batch counts match official", lengths.len(), counts.len());
}

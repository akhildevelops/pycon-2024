# FastTokenizer

Tokenizer built in ziglang, currently supports 0.12.0 version

```zig
var tr = try t.TokenRanker.from_encoding_type("cl100k_base", allocator);
defer tr.free();
const slice = try tr.tokenize("Operations on vectors shorter than the target machine's native SIMD size will typically compile to single ", allocator);
defer allocator.free(slice);
try std.testing.expectEqualSlices(u32, &[_]u32{ 36220, 389, 23728, 24210, 1109, 279, 2218, 5780, 596, 10068, 67731, 1404, 690, 11383, 19742, 311, 3254, 220 }, slice);
```

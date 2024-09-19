const std = @import("std");
const testing = std.testing;
const Regex = @import("jstring").Regex;

test "basic add functionality" {
    var S = "Hello Worl";
    // var jString = try JString.newFromSlice(std.testing.allocator, S);
    // defer jString.deinit();
    var re = try Regex.init(std.testing.allocator,
        \\'(?:[sdmt]|ll|ve|re)| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+
    , 0x00080000);
    defer re.deinit();
    try re.matchAll("Hello World", 0, 0);
    if (re.succeed()) {
        const results = re.getResults().?;
        std.debug.print("{d}", .{results.len});
        for (results) |matched_result| {
            std.debug.print("{s}\n", .{S[matched_result.start .. matched_result.start + matched_result.len]});
        }
    }
    try re.reset();
    S = "Ġmeousrtr";
    try re.matchAll(S, 0, 0);
    if (re.succeed()) {
        const results = re.getResults().?;
        std.debug.print("{d}", .{results.len});
        for (results) |matched_result| {
            std.debug.print("{s}\n", .{S[matched_result.start .. matched_result.start + matched_result.len]});
        }
    }
}

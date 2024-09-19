const std = @import("std");
const Rank = @import("./rank.zig");

pub export fn token_ranker(name: [*:0]const u8, size: usize) *anyopaque {
    const allocator = std.heap.c_allocator;
    const ranker = allocator.create(Rank.TokenRanker) catch @panic("Cannot create TokenRanker in heap");
    ranker.* = Rank.TokenRanker.from_encoding_type(name[0..size], allocator) catch @panic("Cannot initialize TokenRanker");
    return ranker;
}

pub export fn encode(text: [*:0]c_char, token_length: *c_uint, ranker: *anyopaque) [*]c_uint {
    const allocator = std.heap.c_allocator;
    const data: []const u8 = @ptrCast(text[0..std.mem.len(text)]);
    var rranker: *Rank.TokenRanker = @ptrCast(@alignCast(ranker));
    // defer rranker.free();
    const tokens = rranker.tokenize(data, allocator) catch @panic("Cannot tokenize");
    defer allocator.free(tokens);
    var c_int_array = std.ArrayList(c_uint).initCapacity(allocator, tokens.len) catch @panic("Cannot assign a new array");
    c_int_array.expandToCapacity();
    for (0..tokens.len) |index| {
        c_int_array.items[index] = std.math.cast(c_uint, tokens[index]).?;
    }
    token_length.* = std.math.cast(c_uint, tokens.len).?;
    return (c_int_array.toOwnedSlice() catch @panic("Cannot convert to array_slice")).ptr;
}

const Calc = struct {
    a: i32,
    b: i32,
    const Self = @This();
    fn perform(_: *Self, comptime x: i32) !i32 {
        return Self._add(13, 23, x);
    }
    fn _add(a: i32, b: i32, comptime x: i32) !i32 {
        _ = a;
        _ = b;
        _ = x;
        return error.nj;
    }
};

pub export fn add() *anyopaque {
    var c: Calc = .{ .a = 5, .b = 10 };
    const value = c.perform(11);
    return @constCast(&value);
}

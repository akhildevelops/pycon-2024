const std = @import("std");

const fs = std.fs;
const io = std.io;

pub const String = struct {
    str: []const u8,
    const Self = @This();
    pub fn skip_nlines(self: *const Self, n_lines: usize) Self {
        var skipped_lines: usize = 0;
        var start: usize = 0;
        while (skipped_lines < n_lines and start < self.str.len) {
            if (self.str[start] == '\n') {
                skipped_lines += 1;
            }
            start += 1;
        }

        return String{ .str = self.str[start % self.str.len ..] };
    }
};

fn MultiIndexIterator(comptime T: type) type {
    return struct {
        start_index: usize,
        haystack: []const T,
        needle: []const T,

        const Self = @This();
        pub fn next(self: *Self) ?usize {
            const o_index = std.mem.indexOfPos(T, self.haystack, self.start_index, self.needle);
            if (o_index) |index| {
                self.start_index = index + self.needle.len - 1;
            }
            return o_index;
        }
    };
}

fn MultiIndexContextIterator(comptime T: type, comptime C: type, comptime check: fn (T, C) bool) type {
    return struct {
        start_index: usize,
        haystack: []const T,
        context: C,

        const Self = @This();
        pub fn next(self: *Self) ?usize {
            for (self.start_index..self.haystack.len) |index| {
                if (check(self.haystack[index], self.context)) {
                    self.start_index = index + 1;
                    return index;
                }
            }
            return null;
        }
    };
}

pub fn multiIndexOf(comptime T: type, haystack: []const T, needle: []const T) MultiIndexIterator(T) {
    return MultiIndexIterator(T){ .start_index = 0, .haystack = haystack, .needle = needle };
}

pub fn multiIndexOfContext(
    comptime T: type,
    haystack: []const T,
    context: anytype,
    comptime check: fn (T, @TypeOf(context)) bool,
) MultiIndexContextIterator(T, @TypeOf(context), check) {
    return MultiIndexContextIterator(T, @TypeOf(context), check){ .start_index = 0, .haystack = haystack, .context = context };
}

fn iseven(x: u8, _: void) bool {
    return x % 2 == 0;
}
test multiIndexOfContext {
    var m = multiIndexOfContext(u8, &.{ 1, 2, 3, 4, 1, 2, 1 }, {}, iseven);
    try std.testing.expectEqual(m.next().?, 1);
    try std.testing.expectEqual(m.next().?, 3);
    try std.testing.expectEqual(m.next().?, 5);
    try std.testing.expectEqual(m.next(), null);
}

test multiIndexOf {
    var m = multiIndexOf(u8, &.{ 1, 2, 3, 4, 1, 2, 1 }, &.{ 1, 2 });
    try std.testing.expectEqual(m.next().?, 0);
    try std.testing.expectEqual(m.next().?, 4);
    try std.testing.expectEqual(m.next(), null);
}

pub fn revStrHashMap(comptime V: type, source: std.StringHashMap(V), allocator: std.mem.Allocator) !std.HashMap(V, []const u8, std.hash_map.AutoContext(V), std.hash_map.default_max_load_percentage) {
    var destination = std.HashMap(V, []const u8, std.hash_map.AutoContext(V), std.hash_map.default_max_load_percentage).init(allocator);
    var source_iterator = source.iterator();

    while (source_iterator.next()) |kv| {
        try destination.put(kv.value_ptr.*, kv.key_ptr.*);
    }

    return destination;
}

pub fn isPrint(c: u21) error{ CodepointTooLarge, NotYetImplemented }!bool {
    _ = try std.unicode.utf8CodepointSequenceLength(c);
    return switch (c) {
        0x00...0x7f => std.ascii.isPrint(@intCast(c)), // Detect by Ascii
        0x80...0x9f => false, // All are controle chars
        0xa0...0x1ff => true,
        else => error.NotYetImplemented,
    };
}

pub fn _download_file(url: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var data = std.ArrayList(u8).init(allocator);
    var client = std.http.Client{ .allocator = allocator };
    _ = try client.fetch(.{ .location = .{ .url = url }, .response_storage = .{ .dynamic = &data } });
    defer client.deinit();
    return try data.toOwnedSlice();
}

pub fn _store_data(data: []const u8, file_path: []const u8) !void {
    std.debug.print("{s}\n", .{file_path});
    const file = try std.fs.createFileAbsolute(file_path, .{});
    try file.writeAll(data);
}
pub fn read_file(file_path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.openFileAbsolute(file_path, .{});
    defer file.close();
    var buffer_reader = io.bufferedReader(file.reader());
    const content = try buffer_reader.reader().readAllAlloc(allocator, 5 * 1024 * 1024);
    return content;
}
// Check if tokenizer data exists

test "revStHashmap" {
    var source = std.StringHashMap(u32).init(std.testing.allocator);
    defer source.clearAndFree();
    try source.put("Hello", 32);
    try source.put("Hello1", 33);
    try source.put("Hello2", 34);
    try source.put("Hello3", 34);
    var destination = try revStrHashMap(u32, source, std.testing.allocator);
    defer destination.clearAndFree();
    try std.testing.expectEqual(destination.count(), 3);
    try std.testing.expectEqual(destination.get(32).?, "Hello");
    try std.testing.expectEqual(destination.get(33).?, "Hello1");
    // put method in hashmap adds keys to stack, therefore when iterating last key comes first i.e, "Hello3" then "Hello2".
    try std.testing.expectEqual(destination.get(34).?, "Hello2");
}

test "string_skip_nlines" {
    var hello = String{ .str = "Hello/nWorld/nHello/nWorld" };
    var processed_str = hello.skip_nlines(2);
    try std.testing.expectEqualStrings(processed_str.str, hello.str);

    hello = String{ .str = "Hello\nWorld\nHello/nWorld" };
    processed_str = hello.skip_nlines(2);
    try std.testing.expectEqualStrings(processed_str.str, hello.str[12..]);
    try std.testing.expect(!std.mem.eql(u8, processed_str.str, hello.str[13..]));
}

test "unicode_valid_print" {
    try std.testing.expect(try isPrint(32)); // Space char
    try std.testing.expect(try isPrint(33)); // Exclaimation
    try std.testing.expect(try isPrint(0xa1)); // Inverted Exclaimation
    try std.testing.expect(try isPrint(0xa0)); // Non braking space: https://en.wikipedia.org/wiki/Non-breaking_space
}

test "unicode_invalid_print" {
    try std.testing.expect(!(try isPrint(0x7f))); // Control Char
    try std.testing.expect(!(try isPrint(0x9f))); // Control Char
}

test "unicode_not_implemented" {
    try std.testing.expectError(error.NotYetImplemented, isPrint(0x200)); // Control Char
}

const std = @import("std");
const B64Decoder = std.base64.standard.Decoder;
const utils = @import("./utils.zig");
const model = @import("./model.zig");
const encoding = @import("./encoding.zig");
// const Regex = @import("jstring").Regex;
const Regex = @cImport(@cInclude("/home/fancy-regex/fancy_regex.h"));
const fs = std.fs;
const io = std.io;
const RANKMAX = std.math.maxInt(u32);
const INDEXMAX = std.math.maxInt(usize);
const T = struct { usize, u32 };
pub const TokenRanker = struct {
    str_to_id: std.StringHashMap(u32),
    id_to_str: std.HashMap(u32, []const u8, std.hash_map.AutoContext(u32), std.hash_map.default_max_load_percentage),
    allocator: std.mem.Allocator,
    regex: ?*anyopaque,
    const Self = @This();
    pub fn free(self: *Self) void {
        var key_iter = self.str_to_id.keyIterator();
        while (key_iter.next()) |key| {
            self.allocator.free(key.*);
        }
        self.str_to_id.deinit();
        self.id_to_str.deinit();
    }

    pub fn from_encoding_type(name: []const u8, allocator: std.mem.Allocator) !Self {
        var e = try encoding.ENCODING.init(name, allocator);
        defer e.deinit();
        const content = try utils.read_file(e.token_path, allocator);
        defer allocator.free(content);
        var str_to_id = std.StringHashMap(u32).init(allocator);
        try str_to_id.ensureTotalCapacity(std.math.cast(u32, e.n_tokens).?);

        var splits = std.mem.splitScalar(u8, content, '\n');

        while (splits.next()) |line| {
            const index = std.mem.indexOfScalar(u8, line, ' ') orelse continue;
            const decoded_len = try B64Decoder.calcSizeForSlice(line[0..index]);
            var destination = try std.ArrayList(u8).initCapacity(allocator, decoded_len);
            destination.expandToCapacity();
            try B64Decoder.decode(destination.items, line[0..index]);
            const rank = try std.fmt.parseInt(u32, line[index + 1 ..], 10);
            try str_to_id.put(try destination.toOwnedSlice(), rank);
        }
        const id_to_str = try utils.revStrHashMap(u32, str_to_id, allocator);
        const re = Regex.get_regex(@constCast(e.regex_pattern.ptr));
        return Self{ .allocator = allocator, .regex = re, .str_to_id = str_to_id, .id_to_str = id_to_str };
    }

    inline fn get_rank(self: Self, token_indices: std.ArrayList(T), i: usize, word: []const u8) u32 {
        if ((i + 3) < token_indices.items.len) {
            return self.str_to_id.get(word[token_indices.items[i][0]..token_indices.items[i + 3][0]]) orelse RANKMAX;
        }
        return RANKMAX;
    }
    pub fn tokenize(self: *Self, data: []const u8, allocator: std.mem.Allocator) ![]const u32 {
        const matches = Regex.get_matches(self.regex, @constCast(data.ptr)).?;
        var tokens = std.ArrayList(u32).init(allocator);
        if (self.str_to_id.get(data)) |rank| {
            try tokens.append(rank);
            return tokens.toOwnedSlice();
        }

        while (Regex.next(matches)) |match| {
            const word = data[match.*.start..match.*.end];
            var token_indices = try std.ArrayList(T).initCapacity(allocator, word.len + 1);
            defer token_indices.deinit();

            // After iteration of whole word min_rank contains the index and rank that should be merged
            var min_rank: T = .{ INDEXMAX, RANKMAX };
            for (0..word.len - 1) |index| {
                const rank = self.str_to_id.get(word[index .. index + 2]) orelse RANKMAX;
                if (rank < min_rank[1]) {
                    min_rank = .{ index, rank };
                }
                try token_indices.append(.{ index, rank });
            }
            try token_indices.append(.{ word.len - 1, RANKMAX });
            try token_indices.append(.{ word.len, RANKMAX });

            while (min_rank[1] != RANKMAX) {
                // if min_rank[0] is i then i and i+1 are already single token
                // therefore the length shud be i-1,i,i+1 and i,i+1,i+2 i.e, combination of three tokens therefore the index range will be
                // token_indices[i-1..i+2] and tokend_indices[i+1..i+4]
                if (min_rank[0] != 0) {
                    token_indices.items[min_rank[0] - 1][1] = self.get_rank(token_indices, min_rank[0] - 1, word);
                }
                token_indices.items[min_rank[0]][1] = self.get_rank(token_indices, min_rank[0], word);
                _ = token_indices.orderedRemove(min_rank[0] + 1);
                // if not resetted then current ranks in token_indices can never be less than min_rank
                min_rank = .{ INDEXMAX, RANKMAX };
                for (token_indices.items[0 .. token_indices.items.len - 1], 0..) |token_index, i| {
                    if (token_index[1] < min_rank[1]) {
                        min_rank = .{ i, token_index[1] };
                    }
                }
            }
            for (0..token_indices.items.len - 1) |index| {
                // If RANKMAX are present then we can't convert into tokenid so iterating
                const token_id = self.str_to_id.get(word[token_indices.items[index][0]..token_indices.items[index + 1][0]]).?;
                try tokens.append(token_id);
            }
        }

        return tokens.toOwnedSlice();
    }
    pub fn detokenize(self: Self, tokens: []const u32, allocator: std.mem.Allocator) ![]const u8 {
        var text = std.ArrayList(u8).init(allocator);
        for (tokens) |token| {
            try text.appendSlice(self.id_to_str.get(token).?);
        }
        return text.toOwnedSlice();
    }
};

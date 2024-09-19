const std = @import("std");
const utils = @import("utils.zig");
const ENCODING_TYPE = enum {
    r50k_base,
    p50k_base,
    p50k_edit,
    cl100k_base,
    o200k_base,
};

pub const ENCODING = struct {
    encoding_type: ENCODING_TYPE,
    regex_pattern: [:0]const u8,
    n_tokens: usize,
    link: []const u8,
    special_tokens: [][]const u8,
    special_token_values: []usize,
    token_path: []const u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.token_path);
    }

    pub fn init(encoding_type: []const u8, allocator: std.mem.Allocator) !Self {
        var encoding_val: ?Self = null;
        const elements = .{
            .{
                "r50k_base", .{
                    ENCODING_TYPE.r50k_base,
                    \\'(?:[sdmt]|ll|ve|re)| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+
                    ,
                    "https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken",
                    50257,
                    &[_][]const u8{"<|endoftext|>"},
                    &[_]usize{50256},
                },
            },
            .{
                "p50k_base", .{
                    ENCODING_TYPE.p50k_base,
                    \\'(?:[sdmt]|ll|ve|re)| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+
                    ,
                    "https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken",
                    50281,
                    &[_][]const u8{"<|endoftext|>"},
                    &[_]usize{50256},
                },
            },
            .{
                "cl100k_base", .{
                    ENCODING_TYPE.cl100k_base,
                    \\'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]++[\r\n]*|\s*[\r\n]|\s+(?!\S)|\s+
                    ,
                    "https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken",
                    100256,
                    &[_][]const u8{ "<|endoftext|>", "<|fim_prefix|>", "<|fim_middle|>", "<|fim_suffix|>", "<|endofprompt|>" },
                    &[_]usize{ 100257, 100258, 100259, 100260, 100276 },
                },
            },
        };
        inline for (elements) |element| {
            if (std.mem.eql(u8, element[0], encoding_type)) {
                const path = try std.process.getEnvVarOwned(allocator, "HOME");
                defer allocator.free(path);
                const cache_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ path, ".cache/fasttokenizer" });
                defer allocator.free(cache_path);
                _ = try std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{ "mkdir", "-p", cache_path } });
                const file_path = try std.mem.concat(allocator, u8, &[_][]const u8{ cache_path, "/", encoding_type });
                std.fs.accessAbsolute(file_path, .{}) catch |err| {
                    switch (err) {
                        error.FileNotFound => {
                            // Download the artifacts
                            const data = try utils._download_file(element[1][2], allocator);
                            try utils._store_data(data, file_path);
                        },
                        else => {
                            return err;
                        },
                    }
                };
                encoding_val = .{ .allocator = allocator, .encoding_type = element[1][0], .regex_pattern = element[1][1], .link = element[1][2], .n_tokens = element[1][3], .special_tokens = @constCast(element[1][4]), .special_token_values = @constCast(element[1][5]), .token_path = file_path };
            }
        }
        if (encoding_val == null) {
            return error.no_encoding_type;
        }

        return encoding_val.?;
    }
};

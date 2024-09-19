const std = @import("std");
const ModelMeta = struct { name: []const u8, regex_pattern: []const u8, n_tokens: comptime_int };
pub fn get_model(comptime model_name: []const u8) ModelMeta {
    if (std.mem.eql(u8, model_name, "c100k_base")) {
        return .{ .name = "c100k_base", .regex_pattern = 
        \\'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]++[\r\n]*|\s*[\r\n]|\s+(?!\S)|\s+
        , .n_tokens = 100256 };
    } else {
        @compileError("Model Not found");
    }
}

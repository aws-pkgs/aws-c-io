const std = @import("std");
const c = @cImport({
    @cInclude("aws/common/allocator.h");
    @cInclude("aws/io/io.h");
});
const testing = std.testing;

test "basic basic functionality" {
    const allocator = c.aws_default_allocator();
    c.aws_io_library_init(allocator);
    defer c.aws_io_library_clean_up();
}

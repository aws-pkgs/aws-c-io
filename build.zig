const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const t = target.result;
    const aws_c_common_dep = b.dependency("aws-c-common", .{
        .target = target,
        .optimize = optimize,
    });
    const aws_c_io_dep = b.dependency("aws-c-io", .{});
    const lib = b.addStaticLibrary(.{
        .name = "aws-c-io",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(aws_c_io_dep.path("include"));
    lib.linkLibrary(aws_c_common_dep.artifact("aws-c-common"));
    lib.addCSourceFiles(.{
        .root = aws_c_io_dep.path("source"),
        .files = &aws_io_src,
        .flags = &.{},
    });
    lib.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &aws_io_src_vendored,
        .flags = &.{},
    });
    if (t.os.tag != .windows) {
        lib.defineCMacro("BYO_CRYPTO", null);
        lib.addCSourceFiles(.{
            .root = aws_c_io_dep.path("source"),
            .files = &aws_io_posix_src,
            .flags = &.{},
        });
    }
    if (t.os.tag == .windows) {
        lib.linkSystemLibrary("secur32");
        lib.linkSystemLibrary("crypt32");
        lib.linkSystemLibrary("ncrypt");
        lib.linkSystemLibrary("shlwapi");
        lib.defineCMacro("AWS_USE_IO_COMPLETION_PORTS", null);
        lib.addCSourceFiles(.{
            .root = b.path("src"),
            .files = &aws_io_windows_src_vendored,
            .flags = &.{},
        });
        lib.addCSourceFiles(.{
            .root = aws_c_io_dep.path("source"),
            .files = &aws_io_windows_src,
            .flags = &.{},
        });
    } else if (t.os.tag.isBSD() or t.os.tag.isDarwin()) {
        lib.defineCMacro("AWS_USE_KQUEUE", null);
        lib.addCSourceFiles(.{
            .root = b.path("src"),
            .files = &aws_io_bsd_src,
            .flags = &.{},
        });
    } else if (t.os.tag == .linux) {
        lib.defineCMacro("AWS_USE_EPOLL", null);
        lib.addCSourceFiles(.{
            .root = b.path("src"),
            .files = &aws_io_linux_src,
            .flags = &.{},
        });
    } else {
        @panic("unsupported os");
    }
    lib.installHeadersDirectory(b.path("include"), "", .{});
    lib.installHeadersDirectory(aws_c_io_dep.path("include"), "", .{});
    lib.installLibraryHeaders(aws_c_common_dep.artifact("aws-c-common"));
    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.linkLibrary(lib);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

const aws_io_src = [_][]const u8{
    "alpn_handler.c",
    "async_stream.c",
    "channel.c",
    "channel_bootstrap.c",
    "event_loop.c",
    "exponential_backoff_retry_strategy.c",
    "future.c",
    "host_resolver.c",
    //"io.c",
    "message_pool.c",
    "pem.c",
    "pkcs11_lib.c",
    "pkcs11_tls_op_handler.c",
    "retry_strategy.c",
    "socket_channel_handler.c",
    "socket_shared.c",
    "standard_retry_strategy.c",
    "statistics.c",
    "stream.c",
    "tls_channel_handler.c",
    "tls_channel_handler_shared.c",
    //"tracing.c",
};

const aws_io_src_vendored = [_][]const u8{
    "io.c",
};

const aws_io_windows_src = [_][]const u8{
    "windows/host_resolver.c",
};

const aws_io_windows_src_vendored = [_][]const u8{
    "windows/secure_channel_tls_handler.c",
    "windows/shared_library.c",
    "windows/windows_pki_utils.c",
    "windows/winsock_init.c",

    "windows/iocp/iocp_event_loop.c",
    "windows/iocp/pipe.c",
    "windows/iocp/socket.c",
};

const aws_io_posix_src = [_][]const u8{
    "posix/host_resolver.c",
    "posix/pipe.c",
    "posix/shared_library.c",
    "posix/socket.c",
};

const aws_io_bsd_src = [_][]const u8{
    "bsd/kqueue_event_loop.c",
};

const aws_io_linux_src = [_][]const u8{
    "linux/epoll_event_loop.c",
};

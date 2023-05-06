const std = @import("std");
const config = @import("./config.zig");

const PassConfig = config.PassConfig;
const Allocator = std.mem.Allocator;

const Node = struct {
    allocator: Allocator,
    name: []const u8,
    children: []Node,

    pub fn init(allocator: Allocator, name: []const u8, children: []Node) !Node {
        return Node{
            .allocator = allocator,
            .name = try allocator.dupe(u8, name),
            .children = children,
        };
    }

    pub fn deinit(self: Node) void {
        self.allocator.free(self.name);
    }
};

pub fn makeTree(allocator: Allocator, pass_config: PassConfig) !Node {
    const children = try treeRecursive(allocator, pass_config.prefix);

    return try Node.init(allocator, "Password Store", children);
}

fn treeRecursive(allocator: Allocator, path: []const u8) ![]Node {
    var nodes = std.ArrayList(Node).init(allocator);

    var dir = try std.fs.openIterableDirAbsolute(path, .{});
    defer dir.close();

    var iterator = dir.iterate();
    while (try iterator.next()) |f| {
        const file_name_lower = try std.ascii.allocLowerString(allocator, f.name);

        if (f.kind == .Directory) {
            const path_absolute = try std.mem.join(allocator, "/", &.{ path, f.name });

            const children = try treeRecursive(allocator, path_absolute);

            if (children.len > 0) {
                const parent = try Node.init(allocator, f.name, children);

                try nodes.append(parent);
            }

            allocator.free(path_absolute);
        } else if (f.kind == .File) {
            if (std.mem.endsWith(u8, file_name_lower, ".gpg")) {
                const child = try Node.init(allocator, f.name[0..(f.name.len - 4)], &.{});

                try nodes.append(child);
            }
        }

        allocator.free(file_name_lower);
    }

    return nodes.toOwnedSlice();
}

pub fn printTree(root: Node) void {
    printTreeRecursive(root, 0);
}

const StraightVert = "\x7c  ";
const StraightHorz = "\xc4\xc4\xc4";
const TIntersection = "\xc3\xc4\xc4";
const Left = "\xc0  ";

fn printTreeRecursive(node: Node, depth: u64) void {
    std.debug.print("{s}\n", .{node.name});

    var count: usize = 0;
    while (count < depth) : (count += 1) {
        std.debug.print("{s}", .{StraightVert});
    }

    for (node.children) |child| {
        printTreeRecursive(child, depth + 1);
    }
}

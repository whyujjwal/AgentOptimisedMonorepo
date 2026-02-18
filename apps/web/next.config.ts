import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  output: "standalone",
  experimental: {
    // Trace workspace packages from monorepo root so they're included in the
    // standalone bundle (needed for @repo/shared-types, @repo/ui, etc.)
    outputFileTracingRoot: path.join(__dirname, "../../"),
  },
};

export default nextConfig;

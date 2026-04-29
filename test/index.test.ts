import { describe as describeTest, expect, it } from "vitest";
import { describe, vouch } from "../src/index.js";

describeTest("vouch", () => {
  it("freezes the returned artifact", () => {
    const artifact = vouch(
      "sigil-1.0.0.tgz",
      "https://token.actions.githubusercontent.com",
      "https://github.com/0-draft/sigil/.github/workflows/release.yml@refs/tags/v1.0.0",
    );
    expect(Object.isFrozen(artifact)).toBe(true);
    expect(artifact.name).toBe("sigil-1.0.0.tgz");
  });

  it("rejects empty fields", () => {
    expect(() => vouch("", "issuer", "subject")).toThrow();
    expect(() => vouch("name", "", "subject")).toThrow();
    expect(() => vouch("name", "issuer", "")).toThrow();
  });
});

describeTest("describe", () => {
  it("formats the artifact identity line", () => {
    const artifact = vouch("a", "issuer", "subject");
    expect(describe(artifact)).toBe("a vouched by subject via issuer");
  });
});

/**
 * sigil — a github template for repos that ship under signature.
 * the library itself is intentionally trivial. the value is in the chain
 * around it: how this code becomes a published artifact under attestation.
 */

export interface VouchedArtifact {
  readonly name: string;
  readonly issuer: string;
  readonly subject: string;
}

export function vouch(name: string, issuer: string, subject: string): VouchedArtifact {
  if (!name || !issuer || !subject) {
    throw new Error("vouch requires name, issuer, and subject");
  }
  return Object.freeze({ name, issuer, subject });
}

export function describe(artifact: VouchedArtifact): string {
  return `${artifact.name} vouched by ${artifact.subject} via ${artifact.issuer}`;
}

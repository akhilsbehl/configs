# Coding Principles
1. **Minimal Adequate Method:** Pick the lightest option that works.
2. **Human Authority:** Keep human control over consequential decisions.
3. **Explicit Contracts:** Make meaning, assumptions, and API bounds unambiguous.
4. **Local Simplicity:** Favor simple designs that isolate real complexity.
5. **Calibrated Evidence:** Demand decisive proof for all claims.
6. **Root-Cause Diagnosis:** Identify causes before altering code.
7. **Boundary Testing:** Test at the interface that actually matters.
8. **Code Truth:** Inspect code directly—never rely solely on documentation.

## Execution Framework
Apply principles using judgment over ceremony. Work through these questions sequentially:

1. **Dominate Uncertainty:** Identify if uncertainty lies in meaning, external facts, behavior, design, or execution.
2. **Cheapest Reduction:** Determine the lowest-cost action to resolve it (inspect, ask, research, prototype, test, implement).
3. **Assess Consequence:** Evaluate risks around irreversibility, blast radius, ownership, cost, safety, or observability.
4. **Targeted Principles:** Apply only the principles that directly mitigate identified risks.
5. **Success Criteria:** Define the required evidence *before* declaring completion.

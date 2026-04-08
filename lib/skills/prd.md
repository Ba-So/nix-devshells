# PRD Creator

Generate a task-master-optimized PRD using multi-agent codebase research and design.

Description: $ARGUMENTS

## Available Agents

| Agent                   | Role in Workflow                                                   | Model  |
| ----------------------- | ------------------------------------------------------------------ | ------ |
| **codebase-researcher** | Deep codebase exploration to inform PRD design                     | sonnet |
| **software-designer**   | Full RPG design: capabilities, structure, dependencies, risks      | opus   |
| **sql-assistant**       | Schema design, query strategy, indexing — for DB-touching features | opus   |
| **design-assistant**    | UI/UX design, accessibility, interaction — for UI-facing features  | opus   |
| **complexity-analyzer** | Complexity analysis and architectural smell detection              | opus   |

**Core agents**: `codebase-researcher` (Phase 1) and `software-designer` (Phase 3).
**Domain specialists**: spawn `sql-assistant`, `design-assistant`, or `complexity-analyzer`
in Phase 1 (alongside researchers) when the feature description indicates database work,
UI work, or touches complex existing code. Their output feeds into the designer prompt.

## Workflow

### Phase 0: Parse & Scope

1. Receive the user's description from `$ARGUMENTS`.
2. Derive a filename slug from the description (lowercase, hyphens, max 40 chars).
3. Print the initial progress table.

### Phase 1: Deep Codebase Research

Spawn **two codebase-researcher agents** in a **single message** using the Agent tool
with `run_in_background=true`. Both run in parallel.

**Additionally**, if the feature description involves:

- **Database/SQL work** (schema, migrations, queries, data models): also spawn the
  **sql-assistant** agent to audit existing schema patterns, identify antipatterns, and
  recommend indexing/normalization strategies. Include its output in the Phase 3 designer prompt.
- **UI/frontend work** (pages, forms, components, user flows): also spawn the
  **design-assistant** agent to assess existing UI patterns, accessibility gaps, and
  interaction design concerns. Include its output in the Phase 3 designer prompt.
- **Complex existing code** being extended or refactored: also spawn the
  **complexity-analyzer** agent to identify architectural smells and coupling risks.
  Include its output in the Phase 3 designer prompt.

All specialist agents run in parallel with the researchers in the same spawn message.

**Researcher A (Architecture) prompt:**

```
You are a codebase-researcher agent performing an architecture survey.
Your goal: Map the overall architecture of this codebase to inform PRD creation.

Research brief: The user wants to build: <description>

Investigate and report on:
1. Overall project structure -- top-level directories, module organization
2. Key abstractions and patterns -- what conventions does this codebase follow?
3. Technology stack -- languages, frameworks, build system, key dependencies
4. Module boundaries -- how are concerns separated? What are the public interfaces?
5. Dependency flow -- how do modules depend on each other?
6. Testing patterns -- what test framework, where do tests live, coverage patterns
7. Configuration and build -- how is the project configured and built?

Focus on BREADTH over depth. Map the landscape so a designer can make informed decisions.
Use codanna tools (semantic_search_with_context, find_symbol, search_symbols, get_calls,
find_callers) to build a thorough understanding.

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no markdown formatting. Just the raw JSON on one line.
```

**Researcher A output format:**

```json
{
  "project_structure": ["top-level dirs and their roles"],
  "technology_stack": {
    "languages": [],
    "frameworks": [],
    "build_system": "",
    "key_deps": []
  },
  "patterns_and_conventions": ["pattern descriptions"],
  "module_boundaries": [
    { "name": "", "path": "", "responsibility": "", "public_interface": [] }
  ],
  "dependency_flow": [{ "from": "", "to": "", "nature": "" }],
  "testing_patterns": { "framework": "", "location": "", "conventions": "" },
  "build_and_config": { "build_system": "", "config_approach": "" },
  "summary": "<50 words max>"
}
```

**Researcher B (Domain) prompt:**

```
You are a codebase-researcher agent performing focused domain research.
Your goal: Deep-dive the codebase areas relevant to a specific feature request.

Feature request: <description>

Investigate and report on:
1. Existing code that relates to this feature -- files, symbols, modules
2. Adjacent systems -- what code will this feature need to interact with?
3. Data models -- existing types, schemas, databases relevant to this feature
4. Integration points -- APIs, interfaces, hooks where new code would connect
5. Similar patterns -- has something analogous been built before in this codebase?
6. Constraints -- what existing architecture decisions constrain the implementation?
7. Gaps -- what's missing that would need to be created from scratch?

Focus on DEPTH over breadth. Find the specific code that matters.
Use codanna tools (semantic_search_with_context, find_symbol, search_symbols, get_calls,
find_callers, analyze_impact) to trace through the relevant code paths.

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no markdown formatting. Just the raw JSON on one line.
```

**Researcher B output format:**

```json
{
  "relevant_code": [{ "path": "", "symbols": [], "relevance": "" }],
  "adjacent_systems": [{ "name": "", "path": "", "interaction_type": "" }],
  "data_models": [{ "name": "", "path": "", "fields_or_shape": "" }],
  "integration_points": [{ "location": "", "type": "", "description": "" }],
  "similar_patterns": [{ "what": "", "where": "", "how_applicable": "" }],
  "constraints": ["constraint descriptions"],
  "gaps": ["what needs to be created from scratch"],
  "summary": "<50 words max>"
}
```

**SQL Assistant prompt** (spawn only when feature involves database work):

```
You are the sql-assistant agent auditing a codebase for database design quality.

Feature request: <description>

Codebase context: This feature will involve database work. Audit the existing
database-related code and report on:
1. Existing schema patterns -- tables, relationships, constraints found in code
2. Schema antipatterns -- Jaywalking, EAV, Polymorphic Associations, missing FKs, etc.
3. Indexing assessment -- missing indexes, over-indexing, wrong column order
4. Query antipatterns -- SELECT *, Spaghetti Queries, NULL mishandling, LIKE abuse
5. Data type issues -- FLOAT for money, ENUM for variable sets, etc.
6. Recommendations -- specific schema/query improvements for the new feature

Use your 9-aspect diagnostic framework. Focus on what's relevant to the feature.

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no markdown formatting. Just the raw JSON on one line.
```

**SQL Assistant output format:**

```json
{
  "existing_schema": [
    { "table": "", "columns": "", "constraints": "", "issues": [] }
  ],
  "antipatterns_found": [
    { "aspect": "", "antipattern": "", "location": "", "severity": "" }
  ],
  "indexing_assessment": [
    { "table": "", "current_indexes": [], "recommendations": [] }
  ],
  "query_issues": [{ "location": "", "issue": "", "fix": "" }],
  "recommendations_for_feature": [
    "specific recommendation for the new feature"
  ],
  "summary": "<50 words max>"
}
```

**Design Assistant prompt** (spawn only when feature involves UI work):

```
You are the design-assistant agent auditing a codebase for UI/UX quality.

Feature request: <description>

Audit the existing UI-related code and report on:
1. Existing UI patterns -- component structure, layout conventions, design system
2. Accessibility gaps -- contrast, keyboard nav, screen reader support, ARIA usage
3. Form patterns -- validation, error handling, label placement
4. Interaction patterns -- feedback, loading states, affordances
5. Responsive design -- mobile support, breakpoints, touch targets
6. Recommendations -- specific UI/UX improvements for the new feature

Use your 12-aspect diagnostic framework. Focus on what's relevant to the feature.

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no markdown formatting. Just the raw JSON on one line.
```

**Design Assistant output format:**

```json
{
  "existing_patterns": [{ "pattern": "", "location": "", "quality": "" }],
  "accessibility_gaps": [
    { "aspect": "", "issue": "", "location": "", "severity": "" }
  ],
  "form_issues": [{ "location": "", "issue": "", "fix": "" }],
  "interaction_issues": [{ "location": "", "issue": "", "fix": "" }],
  "recommendations_for_feature": [
    "specific recommendation for the new feature"
  ],
  "summary": "<50 words max>"
}
```

### Phase 2: Interactive Checkpoint -- Scope Clarification

Once all research agents complete (researchers + any domain specialists), the orchestrator:

1. Synthesizes the research findings into a concise summary.
2. Presents its understanding of the user's request in light of the codebase.
3. Asks **3-7 clarifying questions** covering:
   - Scope ambiguities
   - Priority trade-offs (e.g., performance vs. ergonomics)
   - Constraints not yet stated
   - Areas where the codebase reveals multiple viable approaches
4. **Stops and waits for the user to respond.**

**Format for the checkpoint output:**

```
## Codebase Research Complete

### Architecture Summary
[3-5 bullet points synthesized from Researcher A]

### Relevant Existing Code
[Key findings from Researcher B -- what already exists]

### Database Assessment (if sql-assistant was spawned)
[Key findings -- schema patterns, antipatterns, indexing, recommendations]

### UI/UX Assessment (if design-assistant was spawned)
[Key findings -- patterns, accessibility gaps, interaction issues, recommendations]

### My Understanding of Your Request
[Orchestrator's interpretation of $ARGUMENTS in light of research]

### Questions Before Design

1. [Scope question]
2. [Priority question]
3. [Constraint question]
4. [Approach question]
...

Please answer these questions so I can proceed with the design phase.
```

**Do NOT proceed to Phase 3 until the user has responded.**

### Phase 3: Solution Design

Spawn a single **software-designer** agent with `run_in_background=true`.

**Designer prompt:**

```
You are a software-designer agent creating an RPG-structured design for a PRD.

Feature request: <description>

User clarifications: <answers from checkpoint>

Codebase architecture: <JSON from Researcher A>

Domain research: <JSON from Researcher B>

Database assessment: <JSON from sql-assistant, if spawned -- otherwise omit>

UI/UX assessment: <JSON from design-assistant, if spawned -- otherwise omit>

Your task: Design the solution using the RPG (Repository Planning Graph) dual-semantics
method. Separate WHAT (functional capabilities) from HOW (code structure), then connect
them with explicit dependencies.

Produce ALL of the following sections:

1. OVERVIEW: Problem statement, target users, success metrics.

2. FUNCTIONAL DECOMPOSITION: Identify capability domains and features within each.
   For each feature: name, description, inputs, outputs, behavior.
   Think about WHAT the system does, not WHERE code lives.

3. STRUCTURAL DECOMPOSITION: Map capabilities to actual code locations.
   For each module: which capability it maps to, path, responsibility, file structure, exports.
   Ground this in the EXISTING codebase structure -- extend, don't reinvent.

4. DEPENDENCY GRAPH: Explicit dependencies between modules.
   Foundation layer (no deps) first, then build up in layers.
   Think: "What must EXIST before I can build this?"
   NO circular dependencies. Every non-foundation module depends on at least one other.

5. IMPLEMENTATION ROADMAP: Turn the dependency graph into phases.
   Each phase: goal, entry criteria, tasks (with depends_on, acceptance_criteria,
   test_strategy), exit criteria, what it delivers.
   Phase 0 = foundation. Tasks within a phase can be parallelized.

6. TEST STRATEGY: Test pyramid ratios, coverage targets, critical test scenarios
   per module (happy path, edge cases, error cases, integration points).

7. ARCHITECTURE DECISIONS: Key design decisions with rationale, alternatives
   considered, trade-offs, and consequences (positive and negative).

8. RISKS: Technical, dependency, and scope risks. Each with impact, likelihood,
   mitigation strategy, and fallback plan.

9. OPEN QUESTIONS: Uncertainties that should be flagged for the user.

Design principles:
- Extend existing patterns, don't fight the codebase
- Keep features atomic and independently testable
- Ensure the dependency graph has no cycles
- Foundation modules MUST have NO dependencies
- Build toward something usable early (MVP-first thinking)

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no markdown formatting. Just the raw JSON on one line.
```

**Designer output format:**

```json
{
  "overview": {
    "problem_statement": "",
    "target_users": "",
    "success_metrics": []
  },
  "functional_decomposition": [
    {
      "capability": "",
      "description": "",
      "features": [
        {
          "name": "",
          "description": "",
          "inputs": "",
          "outputs": "",
          "behavior": ""
        }
      ]
    }
  ],
  "structural_decomposition": [
    {
      "module": "",
      "maps_to_capability": "",
      "path": "",
      "responsibility": "",
      "files": [{ "name": "", "maps_to_feature": "" }],
      "exports": []
    }
  ],
  "dependency_graph": {
    "layers": [
      {
        "name": "",
        "phase": 0,
        "modules": [{ "name": "", "depends_on": [], "provides": "" }]
      }
    ]
  },
  "implementation_roadmap": [
    {
      "phase": 0,
      "name": "",
      "goal": "",
      "entry_criteria": "",
      "tasks": [
        {
          "name": "",
          "depends_on": [],
          "acceptance_criteria": "",
          "test_strategy": ""
        }
      ],
      "exit_criteria": "",
      "delivers": ""
    }
  ],
  "test_strategy": {
    "pyramid": { "unit": 0, "integration": 0, "e2e": 0 },
    "coverage_targets": {},
    "critical_scenarios": [
      {
        "module": "",
        "happy_path": [],
        "edge_cases": [],
        "error_cases": [],
        "integration": []
      }
    ]
  },
  "architecture_decisions": [
    {
      "decision": "",
      "rationale": "",
      "alternatives": [{ "name": "", "trade_offs": "" }],
      "consequences": { "positive": [], "negative": [] }
    }
  ],
  "risks": [
    {
      "category": "",
      "risk": "",
      "impact": "",
      "likelihood": "",
      "mitigation": "",
      "fallback": ""
    }
  ],
  "open_questions": [""]
}
```

### Phase 4: Interactive Checkpoint -- Design Review

Once the designer completes, the orchestrator renders the design in human-readable form:

```
## Proposed Design

### Capabilities
[Capability tree from functional_decomposition -- each capability with its features]

### Code Structure
[From structural_decomposition -- where new/modified code lives, mapped to capabilities]

### Dependency Graph
[From dependency_graph -- layered view, foundation → layers]

### Implementation Phases
[From implementation_roadmap -- phase summaries with task lists]

### Key Decisions
[From architecture_decisions -- decision + rationale + trade-offs]

### Risks
[From risks -- categorized with mitigations]

### Open Questions
[From open_questions]

---

Does this design look right? Would you like to:
- Modify any capabilities or features?
- Change the code structure or module boundaries?
- Adjust the dependency ordering or phases?
- Revisit any architecture decisions?

Once approved, I'll generate the final PRD.
```

**Do NOT proceed to Phase 5 until the user has approved or provided modifications.**

### Phase 5: PRD Assembly & Write

The orchestrator assembles the final PRD from the designer's output, incorporating any
modifications from the user's feedback in Phase 4.

**Output format**: RPG-structured markdown with XML section tags, optimized for
`task-master parse-prd`. The PRD uses these sections:

- `<overview>` -- Problem Statement, Target Users, Success Metrics
- `<functional-decomposition>` -- Capability Tree with Features (description, inputs, outputs, behavior)
- `<structural-decomposition>` -- Repository Structure + Module Definitions
- `<dependency-graph>` -- Dependency Chain with Foundation/Layers/Phases
- `<implementation-roadmap>` -- Development Phases with tasks, entry/exit criteria
- `<test-strategy>` -- Test Pyramid, Coverage, Critical Scenarios
- `<architecture>` -- System Components, Technology Stack, Design Decisions
- `<risks>` -- Technical, Dependency, Scope risks with mitigations
- `<appendix>` -- Open Questions, Glossary

**Do NOT include template instructions or examples in the output -- only real content.**

Write the file to `.taskmaster/docs/<slug>.md` using the Write tool.

After writing, display:

- The file path
- Suggest: `task-master parse-prd .taskmaster/docs/<slug>.md`
- Optionally suggest: `task-master parse-prd .taskmaster/docs/<slug>.md --research`

## Progress Table

Maintain and **reprint on every state change** (agent spawned, agent completed,
checkpoint reached, user responds, PRD written).

```
+-------+---------------------------+-------------------------------------------------+
| Phase |         Activity          |                    Status                       |
+-------+---------------------------+-------------------------------------------------+
|   1   | Research: Architecture    | ✅ Done                                         |
+-------+---------------------------+-------------------------------------------------+
|   1   | Research: Domain          | ✅ Done                                         |
+-------+---------------------------+-------------------------------------------------+
|   1   | Specialist: SQL/UI/etc    | ✅ Done (or N/A if not spawned)                 |
+-------+---------------------------+-------------------------------------------------+
|   2   | Scope Clarification       | 💬 Waiting on User                              |
+-------+---------------------------+-------------------------------------------------+
|   3   | Solution Design           | ⏳ Pending                                      |
+-------+---------------------------+-------------------------------------------------+
|   4   | Design Review             | ⏳ Pending                                      |
+-------+---------------------------+-------------------------------------------------+
|   5   | PRD Assembly              | ⏳ Pending                                      |
+-------+---------------------------+-------------------------------------------------+
```

**Status icons:**

- ✅ Done
- 🔄 Running (agent is working)
- 💬 Waiting on User (interactive checkpoint)
- ⏳ Pending (blocked on prior phase)
- ❌ Failed

## Constraints

- Always deep-dive the codebase -- never skip research
- Always pause at BOTH interactive checkpoints -- never skip user input
- Researchers use codanna for semantic code analysis
- Designer uses codanna to ground design in actual codebase structure
- Final PRD must be parseable by `task-master parse-prd`
- No worktrees needed -- this is a document generation workflow
- Max 6 agents total (2 researchers + up to 3 domain specialists + 1 designer)
- Domain specialists are optional -- only spawn when the feature clearly involves their domain

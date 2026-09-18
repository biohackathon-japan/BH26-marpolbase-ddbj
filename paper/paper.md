---
title: 'DBCLS BioHackathon 2026 report: A knowledge base for the Marchantia genome database MarpolBase, and AI-assisted tools for DDBJ submission'
title_short: 'BioHackJP26: MarpolBase RDF/MCP and DDBJ submission agents'
tags:
  - Semantic web
  - RDF
  - Model Context Protocol
  - Marchantia polymorpha
  - DDBJ
authors:
  - name: Yasuhiro Tanizawa
    affiliation: 1
    role: Conceptualization, Software, Writing – original draft
  - name: Takatomo Fujisawa
    affiliation: 1
    role: Software, Writing – review & editing
affiliations:
  - name: Bioinformation and DDBJ Center, National Institute of Genetics, Japan
    index: 1
date: 18 September 2026
cito-bibliography: paper.bib
event: BH26JP
biohackathon_name: "DBCLS BioHackathon 2026"
biohackathon_url:   "https://2026.biohackathon.org/"
biohackathon_location: "Matsuyama, Japan, 2026"
group: marpolbase-ddbj
# URL to project git repo --- should contain the actual paper.md:
git_url: https://github.com/biohackathon-japan/BH26-marpolbase-ddbj
# This is the short authors description that is used at the
# bottom of the generated paper (typically the first two authors):
authors_short: Tanizawa \& Fujisawa
---


# Introduction

Our group worked on two loosely coupled goals during the DBCLS BioHackathon 2026.

The first was to turn **MarpolBase** [@citesAsDataSource:Tanizawa2025], the genome database of
the liverwort *Marchantia polymorpha* [@citesAsDataSource:Bowman2017], into a knowledge base: to publish its gene, expression and
literature data as RDF, to expose them through a SPARQL endpoint, and to make them
reachable from AI agents through a Model Context Protocol (MCP) server.

The second was to lower the cost of **depositing data in DDBJ**. Preparing a DDBJ
submission file is still largely manual work, and the two side projects reported here —
DFAST-Agent and MARKit — attack that problem from two directions: an agent that
assembles submission files through dialogue with the user, and a tool that builds and
checks marker-sequence submissions mechanically.

Table 1 lists what was produced.

Table: Resources and tools developed or extended during BioHackathon 2026.

| Name | Description and URL |
| ---------------------- | ---------------------------------------------------------- |
| MarpolBase RDF | RDF distribution of the MarpolBase gene, expression and literature data. <https://marchantia.info/rdf/> |
| MarpolBase SPARQL endpoint | Public endpoint, registered with TogoMCP and RDF Portal. <https://marchantia.info/sparql> |
| MarpolBase MCP server | 14 tools giving agents typed access to genes, expression, co-expression and literature. <https://marchantia.info/mcp> |
| dfast-agent-p | Agent that builds DDBJ submission files for prokaryotic genomes via the DFAST API. <https://github.com/nigyta/dfast-agent-p> |
| DFAST-Agent (eukaryote) | GFF-to-DDBJ conversion agent; a web interface backed by a local LLM is also being developed. In development. |
| MARKit | Marker Annotation and Registration Kit, distributed as the container `nigyta/markit:latest`. <https://ggs-staging.ddbj.nig.ac.jp/tools/markit> |

# MarpolBase RDF and MCP server

## What was published

The gene, expression and literature data served by MarpolBase were converted to RDF and
released. The SPARQL endpoint was registered with both TogoMCP and RDF Portal, so
MarpolBase can now be reached from the cross-database query tooling maintained in Japan.
On top of the endpoint we built an MCP server with 14 tools, which lets an LLM agent
query the resource without writing SPARQL by hand.

The tools fall into five groups: gene lookup and search, expression profiles and
condition comparison, co-expression networks, curated gene–literature links, and
controlled-vocabulary resolution. A `run_sparql` tool and a `describe_schema` tool are
also provided so that an agent can fall back to raw SPARQL when the typed tools are not
enough.

## Use cases

We exercised the server with two analyses driven entirely from natural-language prompts.

In the first (Figure \ref{fig1}), the prompt *"tell me the conditions in which MpBNB is
highly expressed"* was answered by retrieving the mean TPM of `MpBNB` across all 161
conditions in MarpolBase, together with the condition attributes (tissue, accession,
stage, sex, mutant, treatment, infection). The gene reaches 27.8 TPM in the antheridium
and stays near zero in thallus, gemma and spore, which the agent could report because the
expression values carry condition metadata rather than bare sample identifiers.

![Expression of *MpBNB* across the 161 conditions in MarpolBase, retrieved through the MCP server from a single natural-language prompt. Left: top 14 conditions by mean TPM, coloured by organ type. Right: the same values grouped by tissue. \label{fig1}](./figures/fig1_expression.png)

In the second (Figure \ref{fig2}), we followed the bisbibenzyl biosynthesis route under
salt stress. Expression values came from MarpolBase; the pathway context — compound
identifiers, reactions and enzyme references — came from external resources reached
through TogoMCP. The committing PKS/CHS step and the shared phenylpropanoid entry are
both salt-induced, and the induction is paralog-selective within every step.

![The bisbibenzyl route under salt stress. (a) Pathway schematic with enzyme steps coloured by the strongest induction among the expressed paralogs of that step. (b) log2 fold change of individual genes over a 100 mM NaCl time course, grouped by step. \label{fig2}](./figures/fig2_pathway.png)

## What MarpolBase and TogoMCP each contribute

Working through these two analyses made the division of labour between a species-specific
resource and a cross-database hub concrete (Table 2).

Only MarpolBase can supply measured expression across its 161 conditions, the
co-expression network (PCC / HRR / MR), DESeq2 differential expression between two
conditions, gene–literature links curated with evidence and role, and controlled-vocabulary
resolution with PECO and PO identifiers. It also carries its own KEGG Orthology
assignments — `mpo:hasKEGG` for 6,563 genes. This last point mattered in practice:
*M. polymorpha* is absent from KEGG GENES, and the enzyme nodes in Figure \ref{fig2}
could be coloured **only** because MarpolBase assigns KO numbers itself.

Only TogoMCP can convert identifiers across 119 databases (TogoID) [@usesMethodIn:Ikeda2022], search the
species-agnostic references (UniProt, PDB, Reactome, Rhea, ChEMBL, MeSH), reach the NCBI
E-utilities for SRA, GEO and PubMed, and dispatch SPARQL to a choice of endpoints.

Table: Where the two resources overlap, and how the overlap differs in kind.

| Capability | MarpolBase | TogoMCP |
| ---------- | ---------- | ------- |
| SPARQL | One own graph (`GRAPH` must be given explicitly) | A choice of endpoints |
| Literature | *Marchantia* papers linked to genes, with evidence and role | Generic PubMed / MeSH search |
| Compounds | Not covered | ChEBI / Rhea / PubChem identifier conversion |
| Gene expression | Measured values for 161 conditions | Not held |

## The two do not meet at the gene identifier

The most useful negative result of the project: **TogoID holds no *M. polymorpha* gene
dataset, and MarpolBase's `get_gene` does not return UniProt accessions.** There is
therefore no identifier-conversion path that carries `Mp3g23300` directly into the TogoMCP
side. We also confirmed that `pfam → uniprot` does not exist as a TogoID route (404),
while `rhea`/`chebi`, `chebi`/`pubchem_compound`, `uniprot`/`rhea`, `uniprot`/`pdb` and
`go`/`uniprot` do (in both directions).

The two resources meet instead at the level of **shared vocabularies**:

1. KO numbers — the junction that made the two-layer map in Figure \ref{fig2} possible.
2. GO and Pfam — assigned by MarpolBase, dereferenceable on the TogoMCP side.
3. Compound identifiers (ChEBI / PubChem) — the junction for metabolome data.

Going through UniProt instead means searching by protein name and organism, which for
paralog families such as MpPAL1–10 is many-to-many and therefore unreliable.

The practical rule we arrived at: use MarpolBase for measured values, conditions,
co-expression and curated literature in *M. polymorpha*; use TogoMCP to carry those
results outward to structures, reactions, compounds, orthologs in other species and
sequence archives; and bridge the two with KO, GO and compound identifiers rather than
with gene identifiers.

# Side project: DFAST-Agent for DDBJ submission

DFAST-Agent is an AI-agent-based assistant for preparing DDBJ submission files. The
submission procedure and the format converters are exposed to the agent as an MCP server,
skills and tools. The agent reads and writes files on **Kura**, the authenticated object
storage provided for DDBJ users, and collects the metadata a submission requires through
dialogue with the user.

**Prokaryotes.** Using the DFAST API for prokaryotic genomes [@usesMethodIn:Tanizawa2018], files held on Kura were
converted into DDBJ submission files. Interactive preparation of a complete submission
file from the terminal succeeded (<https://github.com/nigyta/dfast-agent-p>).

**Eukaryotes.** A converter from GFF to DDBJ submission format was added. Terminal-based
dialogue with the agent successfully collected the required metadata and produced the
submission files. For users who do not work with an AI agent, we additionally built a web
interface backed by a local LLM running on the NIG supercomputer, operating on files in
Kura. Tuning the local-LLM agent proved difficult and the file conversion did not succeed
in that configuration, but the work produced usable knowledge about operating against
Kura. Development continues.

# Side project: MARKit, a marker submission tool

## Background

A submission of barcode sequences such as COI, 16S or ITS often contains hundreds to
thousands of entries, yet the annotation is left to the submitter by hand. Coordinate
shifts, CDS features that do not translate, and disagreement between the declared organism
name and the sequence itself are sometimes found only after registration. **MARKit**
(Marker Annotation and Registration Kit) builds DDBJ MSS-format submission files
mechanically from a FASTA file plus minimal metadata, and inspects them before submission.

The pipeline is: marker assignment → region determination → structural check → organism-name
reconciliation → submission-file generation → report.

## Features

- **Markers are determined, not declared.** Every model (HMM / CM) is applied and the
  marker is decided per entry, so a submission containing mixed markers is processed
  separately per marker and merged into a single submission file at the end. 22 markers
  are supported.
- **The genetic code is chosen by taxon.** Mitochondrial code tables differ between taxa,
  so the taxon is looked up from the declared organism name before reading frames are
  evaluated.
- **Unregistrable shapes are avoided at generation time** — a reading frame that does not
  translate is not emitted as a CDS, and minus-strand hits are normalised to the plus
  strand with the coordinates moved accordingly.
- **Organism-name reconciliation.** Sequences are compared against a reference database by
  distance and adjudicated with per-family calibrated thresholds. Candidates are proposed
  even when no organism name is declared, which helps to settle the species assignment.
- **Metadata can come later.** A FASTA file alone is enough to run the analysis; the
  submission files can be built once the metadata is available.
- **Per-entry decisions after review.** Looking at the analysis, the submitter can withdraw
  an entry from the submission, or register it as `misc_feature` / `misc_RNA` instead of
  `CDS` / `rRNA`.
- **Validated against real submissions.** Generated output is compared against the `.ann`
  files of 91 actual submissions (about 10,000 entries), and this check is re-run whenever
  a feature is added.
- **Distributed as a container** carrying the runtime, the reference data and the code
  (Apptainer 657 MB / OCI 4.7 GB, published as `nigyta/markit:latest`).

## Web interface

To widen the user base, MARKit was embedded in the existing DDBJ Gene/Genome Submission
(GGS) tool as a web interface (Figures \ref{fig3} and \ref{fig4}). MARKit itself is invoked as a
container, so the analysis logic is identical to the command-line version. The interface
has five screens — INPUT, ANALYSIS, BIOLOGICAL SOURCE, COMMON, BUILD & VALIDATE — and
several FASTA files can be analysed with different marker settings in one job. Screens are
bilingual (Japanese and English), and all uploads are validated server-side.

![The MARKit web interface, INPUT screen. Each FASTA file is paired with a marker setting (`auto` lets MARKit decide), and `common.json` and the sample metadata TSV can be supplied here or later. \label{fig3}](./figures/fig3a_markit.png)

![The MARKit web interface, per-entry analysis table. Each entry carries its assigned marker, status, feature location, codon start, query coverage and alerts; from here an entry can be withdrawn from the submission or demoted to `misc_feature` / `misc_RNA`. \label{fig4}](./figures/fig3b_markit.png)

## Status

The command-line version is usable in production, and all five screens of the web version
work end to end.

# Discussion

Publishing MarpolBase as RDF made it possible to link a species-specific plant genome
resource to external resources, and registering the endpoint with TogoMCP and RDF Portal
contributed a plant genome resource to the shared Japanese infrastructure. The most
transferable lesson is the one in Table 2 and the section that follows it: for a resource
covering a species that the major cross-reference hubs do not index, the integration point
is not the gene identifier but the shared vocabularies the resource chooses to assign —
in our case, above all, its own KO assignments.

On the DDBJ side, both DFAST-Agent and MARKit reduce manual work in submission
preparation, but they do so under different assumptions: DFAST-Agent collects what it
needs through dialogue and therefore depends on a capable agent, while MARKit derives what
it can from the sequence itself and asks the submitter only where a decision is genuinely
required. The local-LLM experiment showed that the dialogue-based approach is currently
hard to reproduce without a frontier model, which is an argument for keeping the
deterministic path available alongside it.

## Acknowledgements

We thank the organizers of the DBCLS BioHackathon 2026 and the other participants for
discussion. This work used TogoMCP and RDF Portal maintained by DBCLS.

# References

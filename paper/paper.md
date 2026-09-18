---
title: 'DBCLS BioHackathon 2026 report: A knowledge base for the Marchantia genome database MarpolBase'
title_short: 'BioHackJP26: MarpolBase RDF and MCP server'
tags:
  - Semantic web
  - RDF
  - Model Context Protocol
  - Marchantia polymorpha
  - Gene expression
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

Our goal at the DBCLS BioHackathon 2026 was to turn **MarpolBase**
[@citesAsDataSource:Tanizawa2025], the genome database of the liverwort
*Marchantia polymorpha* [@citesAsDataSource:Bowman2017], into a knowledge base: to publish
its gene, expression and literature data as RDF, to expose them through a SPARQL endpoint,
and to make them reachable from AI agents through a Model Context Protocol (MCP) server.

The question behind this was practical. *M. polymorpha* is not indexed by the major
cross-reference hubs, so it is not obvious that a species-specific resource can be linked
to the wider set of life-science databases at all. Much of what follows is therefore about
*where* the join actually happens.

Table 1 lists what was produced.

Table: Resources and tools developed or extended during BioHackathon 2026.

| Name | Description and URL |
| ---------------------- | ---------------------------------------------------------- |
| MarpolBase RDF | RDF distribution of the MarpolBase gene, expression and literature data. <https://marchantia.info/rdf/> |
| MarpolBase SPARQL endpoint | Public endpoint, registered with TogoMCP and RDF Portal. <https://marchantia.info/sparql> |
| MarpolBase MCP server | 14 tools giving agents typed access to genes, expression, co-expression and literature. <https://marchantia.info/mcp> |

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

# Discussion

Publishing MarpolBase as RDF made it possible to link a species-specific plant genome
resource to external resources, and registering the endpoint with TogoMCP and RDF Portal
contributed a plant genome resource to the shared Japanese infrastructure. The most
transferable lesson is the one in Table 2 and the section that follows it: for a resource
covering a species that the major cross-reference hubs do not index, the integration point
is not the gene identifier but the shared vocabularies the resource chooses to assign —
in our case, above all, its own KO assignments.

The MCP server also changed how the resource is used in practice. Both analyses in this
report were driven from a natural-language prompt rather than from hand-written SPARQL,
and the value of the typed tools was less in saving keystrokes than in carrying the
condition metadata along with the numbers, so that the agent could report *where* a gene
is expressed and not only *how much*.

## Acknowledgements

We thank the organizers of the DBCLS BioHackathon 2026 and the other participants for
discussion. This work used TogoMCP and RDF Portal maintained by DBCLS.

# References

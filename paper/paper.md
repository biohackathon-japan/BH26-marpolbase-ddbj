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
    affiliation: 1, 2
    role: Conceptualization, Software, Writing – original draft
  - name: Takatomo Fujisawa
    affiliation: 2
    role: Software, Writing – review & editing
affiliations:
  - name: RIKEN, Japan
    ror: 01sjwvz98
    index: 1
  - name: National Institute of Genetics, Japan
    ror: 02xg1m795
    index: 2
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

The liverwort *Marchantia polymorpha* [@citesAsDataSource:Bowman2017] has drawn attention
as a new-generation model plant in developmental and evolutionary biology, and a
high-quality reference genome has been determined for it
[@citesAsDataSource:Tanizawa2025]. For bioinformatics the species is attractive for a
further reason: the community maintains an agreed gene nomenclature and gene identifier
system, and researchers use that system when they describe genes in their papers. A gene
mentioned in the literature can therefore be resolved to an identifier with far less
ambiguity than in most species, which is an advantage both for extracting information from
papers and for integrating data across sources.

MarpolBase, the genome database for the species, was published in *Plant and Cell
Physiology* [@citesAsDataSource:Tanizawa2025], selected as an Editor's Choice, and
accompanied by a commentary placing it among the community-building resources that make
*Marchantia* an accessible model system [@citesAsAuthority:Boxall2026].

Our goal at the DBCLS BioHackathon 2026 was to turn that database into a knowledge
base: to publish its gene, expression and literature data as RDF, to expose them through a
SPARQL endpoint, and to make them reachable from AI agents through a Model Context
Protocol (MCP) server.

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
released. The SPARQL endpoint was registered with both TogoMCP
[@usesMethodIn:Kinjo2026] and RDF Portal, so MarpolBase can now be reached from the
cross-database query tooling maintained in Japan.
On top of the endpoint we built an MCP server with 14 tools, which lets an LLM agent
query the resource without writing SPARQL by hand.

The tools fall into five groups: gene lookup and search, expression profiles and
condition comparison, co-expression networks, curated gene–literature links, and
controlled-vocabulary resolution. A `run_sparql` tool and a `describe_schema` tool are
also provided so that an agent can fall back to raw SPARQL when the typed tools are not
enough.

The literature layer is the part the gene identifier system pays off in, and it is
described in its own section below. Both the gene–paper links and the LLM-drafted function
summaries are in the RDF, so an agent retrieves them as data rather than re-reading the
papers.

## Linking the literature to the genes

The gene–literature layer was assembled in a separate effort and imported into MarpolBase.
The pipeline has four steps:

1. Reference lists were parsed out of PDFs and each paper's DOI, PubMed ID and PMC ID
   completed against CrossRef and the NCBI E-utilities. **1,399 papers** were surveyed.
2. The full text of each paper — the abstract only where no full text could be obtained —
   was read and the *Marchantia* genes it mentions identified. 3,020 of the resulting
   records come from full text, 88 from full text plus supplementary files, and only 39
   from an abstract alone.
3. Each (gene, paper) pair was tagged on two axes: an **evidence** code (`experimental`,
   `sequence` or `citation`) and a **role** (`subject`, `tool`, `comparator` or
   `background`), together with a two-to-three-line function note taken from the text. A
   pair that is both `experimental` and `subject` is a **core reference** — the paper
   actually did experiments on that gene — and a gene page shows those by default, with
   the peripheral mentions behind a "more" control.
4. Gene identifiers were normalised to the MpTak_v7.1 assembly and per-gene JSON was
   generated for MarpolBase to ingest.

The result: **510 of the papers carry at least one gene link**, giving **3,147 gene–paper
records** that name **1,455 distinct gene symbols and identifiers**. 1,105 of those resolve
to a v7.1 gene ID, which is 85% of the records; 1,000 records over 530 genes are core
references.

## Why the linking was feasible at all

This is where the point made in the introduction becomes concrete. The exercise works
because the *Marchantia* community has a **gene nomenclature convention and a stable gene
ID system, and both have been adopted widely enough that authors use them in their
papers**. A gene mentioned in running text is therefore not a free-form string: `MpBNB`,
`MpPAL1` and `Mp3g23300` belong to a registered vocabulary, so a mention can be matched
against the nomenclature table and carried to an identifier.

Two details show how much of the work that convention absorbs:

- **Author-specific spellings still resolve.** A paper writing `MpCYCD;1` is matched
  through the nomenclature entry that carries both that symbol and the identifier
  `Mp8g17230`, so a naming style local to one paper does not break the link.
- **Older papers keep their links.** A correspondence table from earlier assemblies to
  MpTak_v7.1 lets papers that predate the current assembly resolve to current identifiers
  — which is what makes a survey reaching back to the 1970s worth doing at all.

Without that discipline the same reading effort would have produced ambiguous strings
rather than links, and there would have been nothing to put in the RDF. The asymmetry is
worth stating plainly: the curation was affordable here because the naming was settled
first.

## Use cases

We exercised the server with three analyses driven entirely from natural-language prompts.

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

The third (Figure \ref{fig3}) asked for the genes on the sex chromosomes that are
mentioned in the literature, drawn on the chromosomes. This one joins three layers at
once — gene positions from the FALDO annotation, the curated gene–paper links, and the
evidence and role codes on each link — and it is also a readable audit of the curation:
of the 155 genes on chrU and chrV, 8 carry a curated reference, through 29 links over 23
distinct papers. An absence in the figure means no curated link, not an absence of
literature, which is the kind of distinction a resource has to make explicit if an agent
is to reason over it.

![Genes on the *M. polymorpha* sex chromosomes that carry a curated reference, assembled from one prompt. (a) chrU and chrV with all 155 genes, the named ones marked, and the 8 with a curated reference highlighted. (b) The 29 gene–paper links behind panel a, with MarpolBase's own evidence and role codes. \label{fig3}](./figures/fig3_sexchr.png)

## What MarpolBase and TogoMCP each contribute

Working through these analyses made the division of labour between a species-specific
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

# Connecting to the server

The MCP server is a remote, streamable-HTTP endpoint at <https://marchantia.info/mcp>. It
needs no local installation: a user adds the URL as a connector in a client that speaks
MCP — in Claude, *Connectors → Add connector → Remote URL*; in the ChatGPT desktop app,
*Settings → Plugins → add an MCP server* over streamable HTTP — and then asks for what
they want in ordinary language. Nothing about the RDF shape or SPARQL syntax has to be
learned first, which was the barrier the endpoint alone did not remove.

We recommend adding TogoMCP (<https://togomcp.rdfportal.org/mcp>) alongside it. The two
together are what produced Figure \ref{fig2}, and the division of labour between them is
the subject of the two sections above.

## Ongoing work

MBEX, the MarpolBase expression database released in 2022, is being rebuilt: its content
is growing from 340 to about 1,400 entries. The bottleneck there is not the data but the
BioSample metadata that describes it, and we have built a tool that uses an LLM to assist
that curation. The target is to have the expanded expression data in place for the
international *Marchantia* workshop in Kobe in November 2026. Everything in this report
therefore describes a resource that is still growing, and the 161 conditions used in
Figure \ref{fig1} are a snapshot of it.

# Discussion

Publishing MarpolBase as RDF made it possible to link a species-specific plant genome
resource to external resources, and registering the endpoint with TogoMCP and RDF Portal
contributed a plant genome resource to the shared Japanese infrastructure. The most
transferable lesson is the one in Table 2 and the section that follows it: for a resource
covering a species that the major cross-reference hubs do not index, the integration point
is not the gene identifier but the shared vocabularies the resource chooses to assign —
in our case, above all, its own KO assignments.

The MCP server also changed how the resource is used in practice. Every analysis in this
report was driven from a natural-language prompt rather than from hand-written SPARQL,
and the value of the typed tools was less in saving keystrokes than in carrying the
metadata along with the values — condition attributes with the expression numbers,
evidence and role codes with the literature links — so that the agent could report *where*
a gene is expressed and *on what grounds* a paper is attached to it, not only how much and
how many.

## Acknowledgements

We thank the organizers of the DBCLS BioHackathon 2026 and the other participants for
discussion. This work used TogoMCP and RDF Portal maintained by DBCLS.

# References

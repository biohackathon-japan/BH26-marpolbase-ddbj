---
title: 'DBCLS BioHackathon 2026 レポート: ゼニゴケゲノムデータベース MarpolBase の知識ベース化'
title_short: 'BioHackJP26: MarpolBase の RDF 化と MCP サーバ'
tags:
  - セマンティックウェブ
  - RDF
  - Model Context Protocol
  - ゼニゴケ (Marchantia polymorpha)
  - 遺伝子発現
authors:
  - name: 谷澤 靖洋 (Yasuhiro Tanizawa)
    affiliation: 1, 2
  - name: 藤澤 貴智 (Takatomo Fujisawa)
    affiliation: 2
affiliations:
  - name: 理化学研究所
    index: 1
  - name: 国立遺伝学研究所
    index: 2
date: 2026年9月18日
event: BH26JP
biohackathon_name: "DBCLS BioHackathon 2026"
biohackathon_url:   "https://2026.biohackathon.org/"
biohackathon_location: "愛媛県松山市, 2026年"
group: marpolbase-ddbj
git_url: https://github.com/biohackathon-japan/BH26-marpolbase-ddbj
---

*本稿は BioHackrXiv 提出版 `paper.md` の日本語版である。*

# はじめに

ゼニゴケ (*Marchantia polymorpha*; Bowman et al., 2017) は、新世代のモデル植物として発生
生物学・進化生物学の分野で注目を集めており、高精度な参照ゲノム配列が決定されている
(Tanizawa et al., 2025)。生物情報学の観点からは、さらにもう一つの利点がある。遺伝子命名ルール
と遺伝子 ID システムが整備されており、多くの研究者が論文中で遺伝子を記載する際にこのシステムを
用いている。そのため、文献中に現れる遺伝子を、多くの生物種の場合よりはるかに曖昧さ少なく ID に
対応づけられる。これは文献からの情報抽出とデータ統合の双方において優位性となる。

本プロジェクトの目標は、この生物種のゲノムデータベース **MarpolBase** (Tanizawa et al., 2025)
を知識ベース化することである。具体的には、遺伝子・発現・文献のデータを RDF として公開し、
SPARQL エンドポイントを通じて提供し、さらに Model Context Protocol (MCP) サーバを介して
AI エージェントから利用できるようにした。

その背後にある問いは実務的なものである。ゼニゴケは主要な横断参照ハブに索引されていないため、
種特異的なリソースをライフサイエンスの広いデータベース群と連結できるかどうか自体が自明では
ない。以下の多くは、その接合点が**どこで**成立するのかについての報告である。

本ハッカソンで作成したリソースとツールを表 1 に示す。

表 1: BioHackathon 2026 で開発・拡張したリソースとツール

| 名称 | URL | 説明 |
| ---- | --- | ---- |
| MarpolBase RDF | <https://marchantia.info/rdf/> | MarpolBase の遺伝子・発現・文献データの RDF 配布 |
| MarpolBase SPARQL エンドポイント | <https://marchantia.info/sparql> | 公開エンドポイント。TogoMCP と RDF Portal に登録済み |
| MarpolBase MCP サーバ | <https://marchantia.info/mcp> | 遺伝子・発現・共発現・文献への型付きアクセスを提供する 14 ツール |

# MarpolBase の RDF 化と MCP サーバ

## 公開したもの

MarpolBase が提供する遺伝子情報・発現情報・文献情報を RDF に変換して公開した。SPARQL
エンドポイントは TogoMCP (Kinjo et al., 2026) と RDF Portal の双方に登録したため、国内で
整備されているデータベース横断のクエリ環境から MarpolBase に到達できるようになった。さらにエンドポイントの
上に 14 個のツールを持つ MCP サーバを構築し、LLM エージェントが SPARQL を自分で書かずに
このリソースを検索できるようにした。

ツールは大きく五つに分かれる。遺伝子の取得と検索、発現プロファイルと条件間比較、共発現
ネットワーク、キュレーション済みの遺伝子–文献リンク、統制語彙の解決である。型付きツールで
足りない場合に備えて `run_sparql` と `describe_schema` も用意し、エージェントが生の SPARQL に
フォールバックできるようにしてある。

## 使用例

自然言語のプロンプトのみで駆動する二つの解析でサーバを検証した。

一つめ (図 1) では、「MpBNB 遺伝子が高発現している条件を教えて」というプロンプトに対し、
MarpolBase の全 161 条件における `MpBNB` の平均 TPM を、条件属性 (組織・系統・ステージ・
性・変異体・処理・感染) とともに取得して回答した。この遺伝子は造精器で 27.8 TPM に達する
一方、葉状体・無性芽・胞子ではほぼゼロである。発現値がサンプル ID ではなく条件メタデータを
伴っているため、エージェントがこのようにまとめて報告できる。

![MCP サーバを介して単一の自然言語プロンプトから取得した、MarpolBase 全 161 条件における *MpBNB* の発現。左: 平均 TPM 上位 14 条件を器官種別で色分けしたもの。右: 同じ値を組織ごとにまとめたもの。](./figures/fig1_expression.png)

二つめ (図 2) では、塩ストレス下におけるビスビベンジル合成経路を追跡した。発現値は
MarpolBase から取得し、代謝経路の文脈 — 化合物 ID、反応、酵素の参照 — は TogoMCP を介して
外部リソースから取得した。律速となる PKS/CHS ステップと、共通のフェニルプロパノイド入口は
ともに塩誘導性であり、しかもどのステップでも誘導はパラログ選択的であった。

![塩ストレス下のビスビベンジル経路。(a) 各ステップを、そのステップで発現しているパラログのうち最も強く誘導されたものの値で色分けした経路図。(b) 100 mM NaCl 時系列における個々の遺伝子の log2 fold change をステップごとにまとめたもの。](./figures/fig2_pathway.png)

## MarpolBase と TogoMCP それぞれの役割

この二つの解析を通じて、種特異的リソースとデータベース横断ハブの役割分担が具体的に見えた
(表 2)。

MarpolBase にしかできないのは、161 条件の実測発現量、共発現ネットワーク (PCC / HRR / MR)、
DESeq2 による 2 条件間の差次発現、evidence と role を付してキュレーションされた遺伝子–文献
リンク、そして PECO・PO ID つきの統制語彙の解決である。加えて、独自の KEGG Orthology 付与を
持つ — `mpo:hasKEGG` で 6,563 遺伝子。この点は実務上重要だった。ゼニゴケは KEGG GENES に
存在しないため、図 2 の酵素ノードを着色できたのは、MarpolBase が自前で KO 番号を付与して
いるからに**他ならない**。

TogoMCP にしかできないのは、119 データベース間の ID 変換 (TogoID; Ikeda et al., 2022)、生物種横断の汎用参照
(UniProt、PDB、Reactome、Rhea、ChEMBL、MeSH) の検索、NCBI E-utilities 経由での SRA・GEO・
PubMed へのアクセス、そして複数エンドポイントを選択しての SPARQL 発行である。

表 2: 両者が重なる部分と、その質の違い

| 機能 | MarpolBase | TogoMCP |
| ---- | ---------- | ------- |
| SPARQL | 自前グラフ 1 つ (`GRAPH` の明示が必須) | 複数エンドポイントを選択可 |
| 文献 | ゼニゴケ論文と遺伝子の紐付け (evidence/role 付き) | PubMed / MeSH の汎用検索 |
| 化合物 | 扱わない | ChEBI / Rhea / PubChem の ID 変換 |
| 遺伝子発現 | 161 条件の実測値 | 持たない |

## 両者は遺伝子 ID では繋がらない

本プロジェクトで最も有用だった否定的な結果がこれである。**TogoID にゼニゴケの遺伝子
データセットは無く、MarpolBase の `get_gene` は UniProt アクセッションを返さない。**
したがって `Mp3g23300` を ID 変換で直接 TogoMCP 側へ渡す経路は存在しない。あわせて、
`pfam → uniprot` は TogoID の経路として存在しない (404) 一方、`rhea ↔ chebi`、
`chebi ↔ pubchem_compound`、`uniprot ↔ rhea`、`uniprot ↔ pdb`、`go ↔ uniprot` は存在する
ことを確認した。

両者が実際に出会うのは**共通語彙のレベル**である。

1. KO 番号 — 図 2 の二層マップを成立させた接点。
2. GO / Pfam — MarpolBase が付与し、TogoMCP 側で参照できる。
3. 化合物 ID (ChEBI / PubChem) — メタボロームデータとの接点。

代わりに UniProt を経由すると、タンパク質名と生物種による検索になるため、MpPAL1〜10 のような
パラログ群では多対多となり信頼できない。

実務上の指針としては次のようになる。ゼニゴケの測定値・条件・共発現・キュレーション文献を
知りたいときは MarpolBase を使う。その結果を構造・反応・化合物・他種のオーソログ・配列
アーカイブへ広げたいときは TogoMCP を使う。そして両者の橋渡しは、遺伝子 ID ではなく
KO・GO・化合物 ID で行う。

# まとめ

MarpolBase を RDF 化することで、種特異的な植物ゲノムリソースを外部リソースと連動させることが
できた。またエンドポイントを TogoMCP と RDF Portal に登録することで、国内の共通基盤に植物
ゲノムリソースを提供できた。他のリソースにも当てはまる教訓は、表 2 とそれに続く節に書いた
とおりである。すなわち、主要な横断参照ハブが索引していない生物種を扱うリソースの場合、統合
の接点は遺伝子 ID ではなく、そのリソースが自ら付与することを選んだ共通語彙 — 本件では何より
独自の KO 付与 — である。

MCP サーバの構築は、このリソースの使われ方も変えた。本稿の二つの解析はいずれも手書きの
SPARQL ではなく自然言語のプロンプトから駆動している。型付きツールの価値は入力の手間を省く
ことよりも、数値に条件メタデータを伴わせる点にあった。そのおかげでエージェントは、ある遺伝子が
**どれだけ**発現しているかだけでなく**どこで**発現しているかを報告できる。

## 参考文献

- Tanizawa Y, Mochizuki T, Yagura M, Sakamoto M, Fujisawa T, Kawamura S, Shimokawa E,
  Yamaoka S, Nishihama R, Bowman JL, Berger F, Yamato KT, Kohchi T, Nakamura Y.
  MarpolBase: genome database for *Marchantia polymorpha* featuring high quality
  reference genome sequences. *Plant and Cell Physiology* 2025;67(3):377-388.
  <https://doi.org/10.1093/pcp/pcaf159>
- Bowman JL, Kohchi T, Yamato KT, et al. Insights into Land Plant Evolution Garnered
  from the *Marchantia polymorpha* Genome. *Cell* 2017;171(2):287-304.e15.
  <https://doi.org/10.1016/j.cell.2017.09.030>
- Ikeda S, Ono H, Ohta T, et al. TogoID: an exploratory ID converter to bridge
  biological datasets. *Bioinformatics* 2022;38(17):4194-4199.
  <https://doi.org/10.1093/bioinformatics/btac491>
- Kinjo AR, Yamamoto Y, Bustamante-Larriet S, Labra-Gayo JE, Fujisawa T. TogoMCP:
  natural language querying of life-science knowledge graphs via schema-guided LLMs and
  the Model Context Protocol. *Database* 2026;2026:baag042.
  <https://doi.org/10.1093/database/baag042>

## 謝辞

DBCLS BioHackathon 2026 の主催者、および議論いただいた参加者の皆様に感謝する。本研究では
DBCLS が維持する TogoMCP と RDF Portal を利用した。

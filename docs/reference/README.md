# Reference Library

`docs/reference/` stores external source material used during game design.

Reference documents are **not project design authority**. They record source mechanics, values, terminology, comparisons, and implementation observations so Game Design can selectively reuse or transform them.

Rules:

- preserve the source version and source context;
- distinguish original source data from our interpretation;
- do not silently replace source values with later/rebalanced versions;
- do not treat a referenced mechanic as accepted project design unless it is explicitly promoted into `docs/design/`;
- where multiple editions exist, store them as separate datasets.

Current collections:

- `weapons/galactic-baseballer/` — weapon research for *The Legend of Galactic Baseballer*; original/base version is the primary dataset for the current project.


## Source priority for 《银河球棒侠传说》

For the original/base-version weapon dataset, use the **official 米游社《崩坏：星穹铁道》WIKI** as the authoritative source for:

- Chinese weapon names;
- Chinese accessory / passive names;
- legendary-weapon names;
- tags / categories;
- level-by-level numerical values;
- effect wording;
- evolution relationships.

Primary page supplied for this dataset:

- https://bbs.mihoyo.com/sr/wiki/content/2989/detail?bbs_presentation_style=no_header

Third-party wikis, guides, and videos may be used only to help locate, cross-check, or recover presentation details that the official page does not expose to the current tooling. They must not override an available official name, value, or wording.

When our tooling cannot extract a dynamically rendered official field, mark it for official-Wiki backfill rather than inventing a translation from an English source.

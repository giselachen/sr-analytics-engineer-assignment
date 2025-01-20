/* 

Questions to Answer:

- Which Glossary Terms have been assigned to datasets and/or dashboards?
- How many datasets and/or dashboards have they been assigned to?

*/ 

with urns_with_terms as (
select
    entity_with_terms.urn,
    glossary_terms,
    json_extract_string(term_flat.term_urns, '$.urn') as term_urn
from
    stg_datahub_entities as entity_with_terms,
    /* Remove cross join and use unnest for consistency throughout the project.
       Also updated the alias names to align with other queries naming conventions */
    unnest(json_extract(glossary_terms, '$.terms')::json[]) as term_flat(term_urns)
where
    entity_with_terms.glossary_terms is not null
)

select
  -- stg_datahub_entities.urn as term_urn,
  /* There are two glossary terms with the same name but different definition so 
     added the definition to differentiate them. It will split the Return Rate counts
     into 9 for eCommerce Return Rate and 7 for animal adaption Return Rate */
  json_extract_string(term_details.entity_details, '$.name') as term_name
  , json_extract_string(term_details.entity_details, '$.definition') as term_definition
  , count(distinct urns_with_terms.urn) as distinct_urn_count
from
  urns_with_terms
left join
  /* Added descriptive alias name and reordered join keys */
  stg_datahub_entities as term_details
  on urns_with_terms.term_urn = term_details.urn
group by 1, 2
order by 3 desc
;

/*

Query Output:

┌───────────────────────┬───────────┐
│       term_name       │ urn_count │
│        varchar        │   int64   │
├───────────────────────┼───────────┤
│ Gold Tier             │       668 │
│ Confidential          │        60 │
│ Return Rate           │        16 │
│ Certification Pending │         1 │
└───────────────────────┴───────────┘

*/
/*

Questions to Answer:

- Which Domain is most commonly applied to datasets and/or dashboards?
- How many datasets and/or dashboards is that Domain applied to?
- What is the description of that Domain?

*/

/* Added a CTE to unnest domain and perform string cleaning - trim outside of the join clause. */
with urns_with_domains as (
select
    entity_with_domains.urn as urn
--    , entity_with_domains.entity_type
    , trim(both '"' from domain_flat.domain_urn) as domain_urn
from
    stg_datahub_entities as entity_with_domains,
    unnest(json_extract_string(entity_with_domains.domains, '$.domains')::string[]) as domain_flat(domain_urn)
where
    entity_with_domains.domains is not null
)

select
--  urns_with_domains.entity_type,
    json_extract_string(domain_details.entity_details, '$.name') as domain_name
    , json_extract_string(domain_details.entity_details, '$.description') as domain_description
    , count(distinct urns_with_domains.urn) as distinct_urn_count     
from 
    urns_with_domains
left join
    stg_datahub_entities as domain_details
    on urns_with_domains.domain_urn = domain_details.urn
group by 1, 2
/* the order by clause below orders the result by domain description and not entity count and 
generates the wrong result. The domain associated with most dataset/dashboard should be 
Finance with 285 counts */
order by 3 desc
limit 1
;


/*

Query Output:

┌─────────────┬────────────────────────────────────────────────────────────────────────────────────────────────┬──────────────┐
│ domain_name │                                       domain_description                                       │ entity_count │
│   varchar   │                                            varchar                                             │    int64     │
├─────────────┼────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────┤
│ E-Commerce  │ The E-Commerce Data Domain within Datahub provides access to datasets related to online reta…  │           65 │
└─────────────┴────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────┘

*/
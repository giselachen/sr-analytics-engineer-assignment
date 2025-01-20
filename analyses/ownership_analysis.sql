/*

Questions to Answer:

- Who has been assigned as owners to dashboards and/or datasets?
- How many dashboards and/or datasets do they own?
- What is their job title?

*/

/* When assign ownership, each user can be a business or a technical
   owner in which the current query result doesn't differentiate. 
   The query can be updated to include additional column for
   differentiation */

/* Added a CTE to unnest owners first */
with urns_with_owners as (
select
    entity_with_owners.urn as urn
    , entity_type
    , json_extract_string(owner_flat.owner_urn, '$.owner') as owner_urn
    --, lower(json_extract_string(owner_flat.owner_urn, '$.type')) as owner_type
from 
    stg_datahub_entities as entity_with_owners,
    unnest(json_extract(owners, '$.owners')::json[]) as owner_flat(owner_urn)
where 
    entity_with_owners.owners is not null
)

select 
    urns_with_owners.entity_type
    --, urns_with_owners.owner_type
    , json_extract_string(user_details.entity_details, '$.username') as username
    , json_extract_string(user_details.entity_details, '$.title') as title
    , count(distinct urns_with_owners.urn) as distinct_urn_count
from 
    urns_with_owners
/* Use lower case left join for consistency. Updated table alias with descriptive 
   terms for readability and consistent */
left join 
    stg_datahub_entities as user_details
    on urns_with_owners.owner_urn = user_details.urn
group by 1, 2, 3--, 4
order by 2, 1;
;

/*

Query Output:

┌─────────────┬───────────────────────┬─────────────────────────┬───────┐
│ entity_type │       username        │          title          │  cnt  │
│   varchar   │        varchar        │         varchar         │ int64 │
├─────────────┼───────────────────────┼─────────────────────────┼───────┤
│ dataset     │ chris@longtail.com    │ Data Engineer           │   218 │
│ dataset     │ eddie@longtail.com    │ Analyst                 │   360 │
│ dataset     │ melina@longtail.com   │ Analyst                 │    24 │
│ dashboard   │ mitch@longtail.com    │ Software Engineer       │    21 │
│ dataset     │ mitch@longtail.com    │ Software Engineer       │    97 │
│ dataset     │ phillipe@longtail.com │ Fulfillment Coordinator │    96 │
│ dataset     │ roselia@longtail.com  │ Analyst                 │    73 │
│ dataset     │ shannon@longtail.com  │ Analytics Engineer      │   300 │
│ dataset     │ terrance@longtail.com │ Fulfillment Coordinator │    32 │
└─────────────┴───────────────────────┴─────────────────────────┴───────┘

*/
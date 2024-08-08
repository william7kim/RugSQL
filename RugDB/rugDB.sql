-- COMP3311 24T2 Assignment 1
-- Written by William Kim (z5348193)
-- Date: June 26, 2024


-- Q1
create or replace view Q1(province, nfactories) as
select 
    locations.province, 
    COUNT(factories.id) as nfactories
from  
    locations
join  
    factories on locations.id = factories.located_in
group by 
    locations.province
;

-- Q2
create or replace view Q2(style, knot_length_diff) as
select
    name as style,
    max_knot_length - min_knot_length as knot_length_diff
from
    styles
group by 
    name, min_knot_length, max_knot_length
having
    max_knot_length - min_knot_length = (
        select MAX(max_knot_length - min_knot_length) 
        from styles
    )
;

-- Q3
create or replace view Q3(style, lo_knot_length, hi_knot_length, min_knot_length, max_knot_length) as
select 
    styles.name as style,
    (select MIN(r.knot_leng) from rugs r where r.style = styles.id) as lo_knot_length,
    (select MAX(r.knot_leng) from rugs r where r.style = styles.id) as hi_knot_length,
    styles.min_knot_length,
    styles.max_knot_length
from 
    styles
where 
    styles.min_knot_length <> styles.max_knot_length
    and (
        (select MIN(r.knot_leng) from rugs r where r.style = styles.id) < styles.min_knot_length
        or 
        (select MAX(r.knot_leng) from rugs r where r.style = styles.id) > styles.max_knot_length
    )
order by
    styles.name
;

-- Q4
create or replace view Q4(factory, rating) as
with RatedRugs as (
    select 
        crafted_by.factory,
        rugs.rating::numeric
    from 
        rugs
    join 
        crafted_by on rugs.id = crafted_by.rug
    where 
        rugs.rating is not null
),
FactoryRatings as (
    select
        factory,
        AVG(rating)::numeric(3,1) as avg_rating,
        COUNT(rating) as rug_count
    from
        RatedRugs
    group by
        factory
    having
        COUNT(rating) >= 5
),
MaxRating as (
    select
        MAX(avg_rating) as max_avg_rating
    from
        FactoryRatings
)
select
    f.name as factory,
    fr.avg_rating as rating
from
    FactoryRatings fr
join
    factories f on fr.factory = f.id
join
    MaxRating mr on fr.avg_rating = mr.max_avg_rating
order by
    f.name
;

-- Q5
create or replace function Q5(pattern text) 
returns table(rug text, size_and_stoper text, total_knots numeric(8,0)) as $$
select 
    r.name as rug,
    r.size || 'sf ' || r.rug_stop as size_and_stoper,
    (COALESCE(r.knot_per_foot, 50) * COALESCE(r.knot_per_foot, 50) * r.size)::numeric(8,0) as total_knots
from 
    rugs r
where 
    r.name ~ pattern;
$$ language sql;

-- Q6
create or replace function Q6(pattern text) 
returns table(province text, first integer, nrugs integer, rating numeric(3,1)) as $$
select 
    loc.province as province,
    MIN(r.year_crafted) as first,
    COUNT(r.id) as nrugs,
    ROUND(AVG(r.rating)::numeric, 1) as rating
from 
    locations loc
join 
    factories f on f.located_in = loc.id
join 
    crafted_by cb on cb.factory = f.id
join 
    rugs r on r.id = cb.rug
where 
    lower(loc.province) like lower('%' || pattern || '%')
group by 
    loc.province
order by 
    loc.province;
$$ language sql;

-- Q7
create or replace function Q7(_rugID integer) 
returns text as $$
declare
    rug_name text;
    material_count integer;
    result text;
    material_record record;
begin
    select name into rug_name
    from rugs
    where id = _rugID;
    
    if not found then
        return 'No such rug (' || _rugID || ')';
    end if;

    select COUNT(*) into material_count
    from contains c
    join materials m on c.material = m.id
    where c.rug = _rugID;

    if material_count = 0 then
        result := '"' || rug_name || '"' || E'\n  no materials recorded';
        return result;
    end if;

    result := '"' || rug_name || '"' || E'\n  contains:';
    for material_record in
        select m.name, m.itype
        from contains c
        join materials m on c.material = m.id
        where c.rug = _rugID
        order by m.name
    loop
        result := result || E'\n    ' || material_record.name || ' (' || material_record.itype || ')';
    end loop;

    return result;
end;
$$ language plpgsql;

-- Q8
drop type if exists RugPiles cascade;
create type RugPiles as (rug text, factory text, piles text);

create or replace function Q8(pattern text) 
returns setof RugPiles as $$
declare
    rug_record record;
    factory_list text;
    piles_list text;
begin
    for rug_record in
        select r.id, r.name,
               string_agg(f.name, '+' order by f.name) as factory_list
        from rugs r
        join crafted_by cb on r.id = cb.rug
        join factories f on cb.factory = f.id
        where lower(r.name) like lower('%' || pattern || '%')
        group by r.id, r.name
    loop
        select string_agg(m.name, ',' order by m.name) into piles_list
        from contains c
        left join materials m on c.material = m.id
        where c.rug = rug_record.id;
        
        if piles_list is null then
            piles_list := 'no piles recorded';
        end if;

        return next (rug_record.name, rug_record.factory_list, piles_list);
    end loop;

    return;
end;
$$ language plpgsql;

-- Q9
drop type if exists Collab cascade;
create type Collab as (factory text, collaborator text);

create or replace function Q9(factoryID integer) 
returns setof Collab as $$
declare
    factory_name text;
    collaborator_name text;
    first_collab boolean := true;
begin
    select name into factory_name from factories where id = factoryID;
    
    if not found then
        return query select 'No such factory (' || factoryID || ')', 'none';
        return;
    end if;
    
    for collaborator_name in
        select distinct f2.name
        from crafted_by cb1
        join crafted_by cb2 on cb1.rug = cb2.rug and cb1.factory <> cb2.factory
        join factories f1 on cb1.factory = f1.id
        join factories f2 on cb2.factory = f2.id
        where f1.id = factoryID
        order by f2.name
    loop
        if first_collab then
            return next (factory_name, collaborator_name);
            first_collab := false;
        else
            return next (null, collaborator_name);
        end if;
    end loop;
    
    if first_collab then
        return query select factory_name, 'none';
    end if;

    return;
end;
$$ language plpgsql;

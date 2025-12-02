-- Verify JOIN works and supervisors exist
SELECT 
    z.name as zone_name, 
    z.supervisor_user_id,
    u.full_name as supervisor_name,
    u.role as supervisor_role
FROM zones z 
LEFT JOIN users u ON z.supervisor_user_id = u.id
WHERE z.city_id = '33333333-3333-3333-3333-333333333333';

-- ============================================================================
-- AUTO-FORWARD TRIGGER: CRC Verification → Ward Assignment
-- ============================================================================
-- When CRC verifies an issue, automatically forward it to the ward

CREATE OR REPLACE FUNCTION public.auto_forward_verified_issue()
RETURNS TRIGGER AS $$
BEGIN
    -- If status changed to 'crc_verified', auto-forward to ward
    IF NEW.status = 'crc_verified' AND OLD.status != 'crc_verified' THEN
        -- Change status to forwarded_to_ward
        NEW.status = 'forwarded_to_ward';
        
        -- Log the auto-forward action
        INSERT INTO public.audit_logs (
            issue_id,
            action,
            performed_by,
            old_data,
            new_data,
            created_at
        ) VALUES (
            NEW.id,
            'auto_forwarded_to_ward',
            auth.uid(),
            jsonb_build_object('status', OLD.status),
            jsonb_build_object('status', 'forwarded_to_ward'),
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_forward_verified_issue ON public.issues;
CREATE TRIGGER trigger_auto_forward_verified_issue
    BEFORE UPDATE OF status ON public.issues
    FOR EACH ROW
    WHEN (NEW.status = 'crc_verified')
    EXECUTE FUNCTION public.auto_forward_verified_issue();

-- ============================================================================
-- COMMENT
-- ============================================================================
COMMENT ON FUNCTION public.auto_forward_verified_issue() IS 
'Automatically forwards CRC-verified issues to ward level without manual intervention';

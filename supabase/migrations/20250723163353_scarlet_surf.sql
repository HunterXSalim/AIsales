/*
  # Add Email Channel Support

  1. Database Changes
    - Update conversation_history to support email channel
    - Update lead_activity_history to support email type
    - Update campaign_sequences to support email type
    - Add email-specific fields and constraints

  2. Security
    - Maintain existing RLS policies
    - Email data follows same security model as other channels

  3. Compatibility
    - Backwards compatible with existing data
    - Extends current channel system
*/

-- Update conversation_history to support email
ALTER TABLE conversation_history 
DROP CONSTRAINT IF EXISTS conversation_history_channel_check;

ALTER TABLE conversation_history 
ADD CONSTRAINT conversation_history_channel_check 
CHECK (channel = ANY (ARRAY['vapi'::text, 'sms'::text, 'whatsapp'::text, 'email'::text]));

-- Update lead_activity_history to support email
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'lead_activity_history' AND column_name = 'email_subject'
  ) THEN
    ALTER TABLE lead_activity_history ADD COLUMN email_subject text;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'lead_activity_history' AND column_name = 'email_body'
  ) THEN
    ALTER TABLE lead_activity_history ADD COLUMN email_body text;
  END IF;
END $$;

-- Update campaign_sequences to support email
ALTER TABLE campaign_sequences 
DROP CONSTRAINT IF EXISTS campaign_sequences_type_check;

ALTER TABLE campaign_sequences 
ADD CONSTRAINT campaign_sequences_type_check 
CHECK (type = ANY (ARRAY['call'::text, 'sms'::text, 'whatsapp'::text, 'email'::text]));

-- Add email template support to campaign_sequences
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'campaign_sequences' AND column_name = 'email_subject'
  ) THEN
    ALTER TABLE campaign_sequences ADD COLUMN email_subject text;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'campaign_sequences' AND column_name = 'email_template'
  ) THEN
    ALTER TABLE campaign_sequences ADD COLUMN email_template text;
  END IF;
END $$;

-- Update ready_sequence_tasks view to include email fields
DROP VIEW IF EXISTS ready_sequence_tasks;

CREATE VIEW ready_sequence_tasks AS
SELECT 
  lsp.id as task_id,
  lsp.lead_id,
  lsp.campaign_id,
  lsp.step,
  lsp.next_at,
  lsp.user_id,
  cs.type as channel_type,
  cs.prompt,
  cs.email_subject,
  cs.email_template,
  cs.wait_seconds,
  ul.name as lead_name,
  ul.phone as lead_phone,
  ul.email as lead_email,
  ul.company_name,
  ul.job_title,
  c.offer as campaign_offer,
  c.calendar_url
FROM lead_sequence_progress lsp
JOIN campaign_sequences cs ON cs.campaign_id = lsp.campaign_id AND cs.step_number = lsp.step
JOIN uploaded_leads ul ON ul.id = lsp.lead_id
JOIN campaigns c ON c.id = lsp.campaign_id
WHERE lsp.status = 'ready'
  AND lsp.next_at <= NOW();

-- Add indexes for email performance
CREATE INDEX IF NOT EXISTS idx_conversation_history_email 
ON conversation_history (campaign_id, channel) 
WHERE channel = 'email';

CREATE INDEX IF NOT EXISTS idx_lead_activity_email 
ON lead_activity_history (campaign_id, type) 
WHERE type = 'email';
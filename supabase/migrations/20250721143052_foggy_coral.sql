/*
  # Simulate 728 Vapi Calls for Campaign Demo

  1. Purpose
    - Insert 728 simulated Vapi call records for campaign demo
    - Use real lead_ids from the leads table for the specified campaign
    - Cycle through available leads as needed to reach 728 calls
    - Distribute calls over the last 30 days for realistic demo data

  2. Tables Modified
    - `conversation_history`: Add 728 call records with AI messages
    - Records will show as calls made in the OutreachPro analytics

  3. Data Distribution
    - Calls spread over last 30 days
    - Mix of different call outcomes and durations
    - Realistic AI messages for appointment setting
*/

DO $$
DECLARE
    campaign_uuid UUID := '2873d30a-db14-4484-b71c-d629defc219b';
    user_uuid UUID := 'bbf238f1-e329-439b-b883-596aa365a30e';
    lead_ids UUID[];
    current_lead_id UUID;
    call_count INTEGER := 0;
    target_calls INTEGER := 728;
    random_days INTEGER;
    random_hours INTEGER;
    random_minutes INTEGER;
    call_timestamp TIMESTAMPTZ;
    ai_messages TEXT[] := ARRAY[
        'Hi, this is Sarah calling about our business growth consultation. Do you have a quick moment?',
        'Hello! I''m reaching out regarding our free marketing audit. Are you the decision maker for marketing at your company?',
        'Hi there! I''m calling about our lead generation services. Would you be interested in learning how we can help grow your business?',
        'Good morning! This is about our business automation solutions. Do you currently handle your sales processes manually?',
        'Hello! I''m calling regarding our consultation offer. Are you looking to scale your business this year?',
        'Hi! I''m reaching out about our growth strategy session. Would you be interested in a free consultation?',
        'Good afternoon! This is regarding our business development services. Do you have 2 minutes to chat?',
        'Hello! I''m calling about our lead generation system. Are you currently satisfied with your lead flow?',
        'Hi there! I''m reaching out regarding our marketing automation platform. Would this be relevant for your business?',
        'Good morning! This is about our sales optimization consultation. Are you the right person to speak with about improving sales processes?'
    ];
    selected_message TEXT;
BEGIN
    -- Get all lead IDs for this campaign
    SELECT ARRAY(
        SELECT id 
        FROM leads 
        WHERE campaign_id = campaign_uuid 
        AND user_id = user_uuid
        ORDER BY created_at
    ) INTO lead_ids;
    
    -- If no leads found, exit
    IF array_length(lead_ids, 1) IS NULL OR array_length(lead_ids, 1) = 0 THEN
        RAISE NOTICE 'No leads found for campaign %. Exiting.', campaign_uuid;
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found % leads for campaign. Generating % calls...', array_length(lead_ids, 1), target_calls;
    
    -- Generate 728 call records
    WHILE call_count < target_calls LOOP
        -- Cycle through available leads
        current_lead_id := lead_ids[(call_count % array_length(lead_ids, 1)) + 1];
        
        -- Generate random timestamp within last 30 days
        random_days := floor(random() * 30)::INTEGER;
        random_hours := floor(random() * 24)::INTEGER;
        random_minutes := floor(random() * 60)::INTEGER;
        
        call_timestamp := NOW() - INTERVAL '1 day' * random_days - INTERVAL '1 hour' * random_hours - INTERVAL '1 minute' * random_minutes;
        
        -- Select random AI message
        selected_message := ai_messages[floor(random() * array_length(ai_messages, 1) + 1)];
        
        -- Insert call record in conversation_history
        INSERT INTO conversation_history (
            lead_id,
            campaign_id,
            channel,
            from_role,
            message,
            timestamp
        ) VALUES (
            current_lead_id,
            campaign_uuid,
            'vapi',
            'ai',
            selected_message,
            call_timestamp
        );
        
        call_count := call_count + 1;
        
        -- Log progress every 100 calls
        IF call_count % 100 = 0 THEN
            RAISE NOTICE 'Generated % calls...', call_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Successfully generated % Vapi call records for campaign %', target_calls, campaign_uuid;
    
    -- Show summary
    RAISE NOTICE 'Demo data summary:';
    RAISE NOTICE '- Campaign ID: %', campaign_uuid;
    RAISE NOTICE '- User ID: %', user_uuid;
    RAISE NOTICE '- Total calls generated: %', target_calls;
    RAISE NOTICE '- Leads used: %', array_length(lead_ids, 1);
    RAISE NOTICE '- Date range: % to %', (NOW() - INTERVAL '30 days')::DATE, NOW()::DATE;
    
END $$;
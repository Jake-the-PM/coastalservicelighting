-- relay_commands table for Bridge Mode
-- This table stores commands sent from remote apps to be executed by the local Bridge device

CREATE TABLE IF NOT EXISTS relay_commands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_id UUID REFERENCES installations(id) ON DELETE CASCADE,
  controller_ip TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('power', 'brightness', 'color', 'effect')),
  payload JSONB DEFAULT '{}',
  processed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup of unprocessed commands
CREATE INDEX IF NOT EXISTS idx_relay_pending 
ON relay_commands (installation_id, processed) 
WHERE processed = FALSE;

-- Enable Realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE relay_commands;

-- RLS Policies
ALTER TABLE relay_commands ENABLE ROW LEVEL SECURITY;

-- Installers can send commands to their installations
CREATE POLICY "Installers can insert commands" ON relay_commands
  FOR INSERT WITH CHECK (
    installation_id IN (
      SELECT id FROM installations WHERE installer_id = auth.uid()
    )
  );

-- Homeowners can send commands to their installations
CREATE POLICY "Homeowners can insert commands" ON relay_commands
  FOR INSERT WITH CHECK (
    installation_id IN (
      SELECT id FROM installations WHERE homeowner_id = auth.uid()
    )
  );

-- Bridge devices can read and update commands for their installations
CREATE POLICY "Bridge can read commands" ON relay_commands
  FOR SELECT USING (
    installation_id IN (
      SELECT id FROM installations WHERE installer_id = auth.uid() OR homeowner_id = auth.uid()
    )
  );

CREATE POLICY "Bridge can mark processed" ON relay_commands
  FOR UPDATE USING (
    installation_id IN (
      SELECT id FROM installations WHERE installer_id = auth.uid() OR homeowner_id = auth.uid()
    )
  );

-- Auto-cleanup: Delete processed commands older than 1 hour
CREATE OR REPLACE FUNCTION cleanup_old_commands() RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM relay_commands 
  WHERE processed = TRUE 
  AND created_at < NOW() - INTERVAL '1 hour';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_commands
  AFTER INSERT ON relay_commands
  EXECUTE FUNCTION cleanup_old_commands();
